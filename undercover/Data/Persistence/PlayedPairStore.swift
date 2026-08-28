//  PlayedPairStore.swift
//  undercoverApp
//
//  SwiftData-backed persistent store for tracking used word concepts.
//  Now tracks BOTH civilian and undercover concepts for proper uniqueness.

import Foundation
import SwiftData
import os

// MARK: - Model

@Model
public final class PlayedPairRecord {
    /// Unique identifier: normalized pair (ordered) + topic
    /// Example: "adidas|nike|fast-food" (not "mcdonalds|fast-food")
    @Attribute(.unique) public var compositeKey: String

    /// Normalized civilian concept (first non-empty value)
    public var civilianConcept: String

    /// Normalized undercover concept (first non-empty value)
    public var undercoverConcept: String

    /// The topic this pair was played in (normalized)
    public var topic: String

    /// Timestamp when marked as played
    public var playedAt: Date

    public init(
        civilian: String,
        undercover: String,
        topic: String
    ) {
        let c = NormalizationUtility.normalize(civilian)
        let u = NormalizationUtility.normalize(undercover)
        let t = NormalizationUtility.normalize(topic)

        // Canonical pair key: min|max for consistent ordering
        let pairKey = NormalizationUtility.pairKey(civilian, undercover)

        self.civilianConcept = c
        self.undercoverConcept = u
        self.topic = t
        self.compositeKey = "\(pairKey)|\(t)"
        self.playedAt = Date()
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
    }

    // MARK: - Public API

    /// Get all normalized concepts played in a topic.
    ///
    /// Returns a Set of all individual words (both civilian and undercover)
    /// that have been used in any pair for this topic.
    public func usedConcepts(for topic: String) async -> Set<String> {
        let records = await fetchRecords(for: topic)

        var concepts = Set<String>()
        for record in records {
            concepts.insert(record.civilianConcept)
            concepts.insert(record.undercoverConcept)
        }
        return concepts
    }

    /// Check if a pair can be used (both concepts not previously played).
    ///
    /// Returns false if either the exact pair or individual concepts were played before.
    public func canUseWords(
        civilian: String,
        undercover: String,
        topic: String
    ) async -> Bool {

        let civNorm = NormalizationUtility.normalize(civilian)
        let uncNorm = NormalizationUtility.normalize(undercover)
        let topicNorm = NormalizationUtility.normalize(topic)

        // Check if the exact pair already exists
        let pairKey = NormalizationUtility.pairKey(civilian, undercover)
        let exactComposite = "\(pairKey)|\(topicNorm)"

        let context = ModelContext(self.container)
        let descriptor = FetchDescriptor<PlayedPairRecord>(
            predicate: #Predicate { $0.compositeKey == exactComposite }
        )

        if (try? context.fetchCount(descriptor)) ?? 0 > 0 {
            // Exact pair already played
            return false
        }

        // Check if either concept was used before (in any pair for this topic)
        let records = await fetchRecords(for: topic)
        for record in records {
            if record.civilianConcept == civNorm ||
               record.undercoverConcept == civNorm ||
               record.civilianConcept == uncNorm ||
               record.undercoverConcept == uncNorm {
                return false
            }
        }

        return true
    }

    /// Mark a pair as played for a topic.
    ///
    /// If the pair already exists (duplicate), insertion fails silently
    /// and is logged as a notice.
    public func markAsPlayed(
        civilian: String,
        undercover: String,
        topic: String
    ) async throws {

        let record = PlayedPairRecord(
            civilian: civilian,
            undercover: undercover,
            topic: topic
        )

        let context = ModelContext(self.container)
        context.insert(record)

        try context.save()

        Self.logger.notice(
            """
            ✅ Marked as played: \(civilian) / \(undercover) (topic: \(topic))
            """
        )
    }

    /// Clear history for a topic, or everything if topic is empty.
    public func clearHistory(for topic: String = "") async {
        let context = ModelContext(self.container)
        let normalizedTopic = NormalizationUtility.normalize(topic)
        let descriptor = topic.isEmpty
            ? FetchDescriptor<PlayedPairRecord>()
            : FetchDescriptor<PlayedPairRecord>(
                predicate: #Predicate { $0.topic == normalizedTopic }
            )

        let records = (try? context.fetch(descriptor)) ?? []
        records.forEach { context.delete($0) }

        do {
            try context.save()
            Self.logger.notice("ℹ️ Cleared history for topic: \(topic.isEmpty ? "all" : topic)")
        } catch {
            Self.logger.error("⚠️ PlayedPairStore clearHistory save failed: \(String(describing: error))")
        }
    }

    /// Count records for a topic (or all if topic is empty).
    public func count(for topic: String = "") async -> Int {
        let context = ModelContext(self.container)
        let normalizedTopic = NormalizationUtility.normalize(topic)
        let descriptor = topic.isEmpty
            ? FetchDescriptor<PlayedPairRecord>()
            : FetchDescriptor<PlayedPairRecord>(
                predicate: #Predicate { $0.topic == normalizedTopic }
            )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Distinct topics that have history.
    public func topics() async -> [String] {
        let context = ModelContext(self.container)
        let descriptor = FetchDescriptor<PlayedPairRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        var distinct = Set<String>()
        for record in records {
            distinct.insert(record.topic)
        }
        return Array(distinct).sorted()
    }


    // MARK: - Private

    private func fetchRecords(for topic: String) async -> [PlayedPairRecord] {
        let context = ModelContext(self.container)
        let normalizedTopic = NormalizationUtility.normalize(topic)

        let descriptor = FetchDescriptor<PlayedPairRecord>(
            predicate: #Predicate { $0.topic == normalizedTopic }
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}
