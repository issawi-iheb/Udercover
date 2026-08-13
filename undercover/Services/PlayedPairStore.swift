//
//  PlayedPairStore.swift
//  undercoverApp
//
//  SwiftData-backed store. Fetch and save happen on a background context
//  to avoid blocking the main thread as history grows.
//

import Foundation
import SwiftData

// MARK: - Model

@Model
public final class PlayedPairRecord {
    public var trackingKey: String
    public var topic:       String
    public var playedAt:    Date

    public init(trackingKey: String, topic: String) {
        self.trackingKey = trackingKey
        self.topic       = topic
        self.playedAt    = Date()
    }
}

// MARK: - Store

public final class PlayedPairStore: Sendable {

    private let container: ModelContainer

    public init() {
        let schema = Schema([PlayedPairRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: fallback)
            print("⚠️ PlayedPairStore: using in-memory fallback — \(error)")
        }
    }

    // MARK: - Public API

    /// All tracking keys played for a topic. Pass `""` for all topics.
    public func usedKeys(for topic: String) async -> Set<String> {
        await withCheckedContinuation { continuation in
            Task.detached {
                let context    = ModelContext(self.container)
                let descriptor = self.descriptor(for: topic)
                let records    = (try? context.fetch(descriptor)) ?? []
                continuation.resume(returning: Set(records.map(\.trackingKey)))
            }
        }
    }

    /// Mark a pair as played. No-ops on duplicate.
    public func markPlayed(trackingKey: String, topic: String) async {
        let key = trackingKey.lowercased()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task.detached {
                let context = ModelContext(self.container)
                let existing = FetchDescriptor<PlayedPairRecord>(
                    predicate: #Predicate { $0.trackingKey == key && $0.topic == topic }
                )
                if (try? context.fetchCount(existing)) == 0 {
                    context.insert(PlayedPairRecord(trackingKey: key, topic: topic))
                    try? context.save()
                }
                continuation.resume()
            }
        }
    }

    /// Clear history for a topic, or everything if `topic` is empty.
    public func clearHistory(for topic: String = "") async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task.detached {
                let context = ModelContext(self.container)
                let records = (try? context.fetch(self.descriptor(for: topic))) ?? []
                records.forEach { context.delete($0) }
                try? context.save()
                continuation.resume()
            }
        }
    }

    // MARK: - Private

    private func descriptor(for topic: String) -> FetchDescriptor<PlayedPairRecord> {
        topic.isEmpty
            ? FetchDescriptor<PlayedPairRecord>()
            : FetchDescriptor<PlayedPairRecord>(predicate: #Predicate { $0.topic == topic })
    }
}
