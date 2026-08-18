//
//  PlayedPairStore.swift
//  undercoverApp
//
//  SwiftData-backed store. Fetch and save happen on a background context
//  to avoid blocking the main thread as history grows.
//

import Foundation
import SwiftData
import os

// MARK: - Model

@Model
public final class PlayedPairRecord {
    @Attribute(.unique) public var compositeKey: String
    public var trackingKey: String
    public var topic:       String
    public var playedAt:    Date

    public init(trackingKey: String, topic: String) {
        let key = trackingKey.lowercased()
        let top = topic.lowercased()
        self.trackingKey = key
        self.topic       = top
        self.compositeKey = "\(key)|\(top)"
        self.playedAt    = Date()
    }
}

// MARK: - Store

public actor PlayedPairStore {

    private let container: ModelContainer
    private static let logger = Logger(subsystem: "undercoverApp", category: "PlayedPairStore")

    public init() {
        let schema = Schema([PlayedPairRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: fallback)
            Self.logger.warning("⚠️ PlayedPairStore: using in-memory fallback — \(String(describing: error))")
        }
        Task { await self.migrateIfNeeded() }
    }

    // MARK: - Public API

    /// All tracking keys played for a topic. Pass `""` for all topics.
    public func usedKeys(for topic: String) async -> Set<String> {
        let context    = ModelContext(self.container)
        let descriptor = self.descriptor(for: topic)
        let records    = (try? context.fetch(descriptor)) ?? []
        return Set(records.map(\.trackingKey))
    }

    /// Mark a pair as played. No-ops on duplicate.
    public func markPlayed(trackingKey: String, topic: String) async {
        let key = trackingKey.lowercased()
        let normalizedTopic = topic.lowercased()
        let context = ModelContext(self.container)
        let record = PlayedPairRecord(trackingKey: key, topic: normalizedTopic)
        context.insert(record)
        do {
            try context.save()
        } catch {
            // Duplicate or other persistence error — treat duplicate as no-op
            Self.logger.notice("ℹ️ Duplicate played pair ignored (key: \(key), topic: \(normalizedTopic)) — \(String(describing: error))")
        }
    }

    /// Clear history for a topic, or everything if `topic` is empty.
    public func clearHistory(for topic: String = "") async {
        let context = ModelContext(self.container)
        let records = (try? context.fetch(self.descriptor(for: topic))) ?? []
        records.forEach { context.delete($0) }
        do {
            try context.save()
        } catch {
            Self.logger.error("⚠️ PlayedPairStore clearHistory save failed: \(String(describing: error))")
        }
    }

    /// Convenience: Clear all history.
    public func clearAllHistory() async {
        await clearHistory(for: "")
    }

    /// Count records for a topic (or all if topic is empty).
    public func count(for topic: String = "") async -> Int {
        let context = ModelContext(self.container)
        let descriptor = self.descriptor(for: topic)
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Distinct topics that have history, normalized (lowercased) and sorted.
    public func topics() async -> [String] {
        let context = ModelContext(self.container)
        let descriptor = FetchDescriptor<PlayedPairRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        let distinct = Set(records.map { $0.topic.lowercased() })
        return Array(distinct).sorted()
    }

    // MARK: - Migration

    private func migrateIfNeeded() async {
        let context = ModelContext(self.container)
        let descriptor = FetchDescriptor<PlayedPairRecord>()
        let records = (try? context.fetch(descriptor)) ?? []

        var seen = Set<String>()
        var deletedCount = 0

        for record in records {
            let key = record.trackingKey.lowercased()
            let top = record.topic.lowercased()
            let composite = "\(key)|\(top)"

            if seen.contains(composite) {
                context.delete(record)
                deletedCount += 1
            } else {
                record.trackingKey  = key
                record.topic        = top
                record.compositeKey = composite
                seen.insert(composite)
            }
        }

        do {
            try context.save()
            if deletedCount > 0 {
                Self.logger.notice("ℹ️ Migration: normalized topics/keys and removed \(deletedCount) duplicates.")
            }
        } catch {
            Self.logger.error("⚠️ Migration failed: \(String(describing: error))")
        }
    }

    // MARK: - Private

    private func descriptor(for topic: String) -> FetchDescriptor<PlayedPairRecord> {
        topic.isEmpty
            ? FetchDescriptor<PlayedPairRecord>()
            : FetchDescriptor<PlayedPairRecord>(predicate: #Predicate { $0.topic == topic })
    }
}
