
//
//  PlayedPairStore.swift
//  undercoverApp
//
//  SwiftData-backed persistent store for tracking used word concepts.
//

import Foundation
import SwiftData
import os

// MARK: - Model

@Model
public final class PlayedPairRecord {

    /// Canonical pair + topic.
    ///
    /// Example:
    /// "adidas|nike|fast-food"
    @Attribute(.unique)
    public var compositeKey: String

    /// Normalized civilian concept.
    public var civilianConcept: String

    /// Normalized undercover concept.
    public var undercoverConcept: String

    /// Normalized topic.
    public var topic: String

    /// Date when the pair was played.
    public var playedAt: Date

    public init(
        civilian: String,
        undercover: String,
        topic: String
    ) {
        let civilianNormalized =
            NormalizationUtility.normalize(civilian)

        let undercoverNormalized =
            NormalizationUtility.normalize(undercover)

        let topicNormalized =
            NormalizationUtility.normalize(topic)

        let pairKey =
            NormalizationUtility.pairKey(
                civilian,
                undercover
            )

        self.civilianConcept = civilianNormalized
        self.undercoverConcept = undercoverNormalized
        self.topic = topicNormalized
        self.compositeKey =
            "\(pairKey)|\(topicNormalized)"
        self.playedAt = Date()
    }
}

// MARK: - Store

public actor PlayedPairStore {

    private let container: ModelContainer

    private static let logger = Logger(
        subsystem: "undercoverApp",
        category: "PlayedPairStore"
    )

    // MARK: - Initialization

    /// Creates the persistent production store.
    public init() {
        let schema = Schema([
            PlayedPairRecord.self
        ])

        do {
            let applicationSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            try FileManager.default.createDirectory(
                at: applicationSupportURL,
                withIntermediateDirectories: true
            )

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            container = try ModelContainer(
                for: schema,
                configurations: configuration
            )

        } catch {
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            container = try! ModelContainer(
                for: schema,
                configurations: fallbackConfiguration
            )

            Self.logger.warning(
                "PlayedPairStore: using in-memory fallback — \(String(describing: error))"
            )
        }
    }

    /// Creates a store with configurable persistence.
    ///
    /// Use `isStoredInMemoryOnly: true` in tests to guarantee
    /// isolation from the user's persistent game history.
    public init(isStoredInMemoryOnly: Bool) {
        let schema = Schema([
            PlayedPairRecord.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            fatalError(
                "Failed to create PlayedPairStore: \(error)"
            )
        }
    }

    // MARK: - Used Concepts

    /// Returns every concept that has already been played
    /// for the specified topic.
    ///
    /// Both civilian and undercover concepts are included.
    public func usedConcepts(
        for topic: String
    ) async -> Set<String> {

        let records = fetchRecords(
            for: topic
        )

        var concepts = Set<String>()

        for record in records {

            if !record.civilianConcept.isEmpty {
                concepts.insert(
                    record.civilianConcept
                )
            }

            if !record.undercoverConcept.isEmpty {
                concepts.insert(
                    record.undercoverConcept
                )
            }
        }

        return concepts
    }

    // MARK: - Can Use

    /// Returns true when the pair has never been played
    /// and neither concept has been used for the topic.
    public func canUseWords(
        civilian: String,
        undercover: String,
        topic: String
    ) async -> Bool {

        let civilianNormalized =
            NormalizationUtility.normalize(civilian)

        let undercoverNormalized =
            NormalizationUtility.normalize(undercover)

        let topicNormalized =
            NormalizationUtility.normalize(topic)

        let pairKey =
            NormalizationUtility.pairKey(
                civilian,
                undercover
            )

        let compositeKey =
            "\(pairKey)|\(topicNormalized)"

        let context = ModelContext(container)

        let descriptor =
            FetchDescriptor<PlayedPairRecord>(
                predicate: #Predicate {
                    $0.compositeKey == compositeKey
                }
            )

        // Exact pair already played.
        if let count = try? context.fetchCount(descriptor),
           count > 0 {
            return false
        }

        let records = fetchRecords(
            for: topic
        )

        // Individual concept already used.
        for record in records {

            if record.civilianConcept == civilianNormalized ||
               record.undercoverConcept == civilianNormalized ||
               record.civilianConcept == undercoverNormalized ||
               record.undercoverConcept == undercoverNormalized {

                return false
            }
        }

        return true
    }

    // MARK: - Mark Played

    /// Persists a pair as played.
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

        let context = ModelContext(container)

        context.insert(record)

        do {
            try context.save()

            Self.logger.notice(
                """
                Marked as played:
                \(civilian) / \(undercover)
                topic: \(topic)
                """
            )

        } catch {

            Self.logger.error(
                """
                Failed to mark pair as played:
                \(civilian) / \(undercover)
                topic: \(topic)
                error: \(String(describing: error))
                """
            )

            throw error
        }
    }

    // MARK: - Clear History

    /// Clears played history.
    ///
    /// Pass a topic to clear only that topic.
    /// Pass an empty string to clear all history.
    public func clearHistory(
        for topic: String = ""
    ) async {

        let context = ModelContext(container)

        let normalizedTopic =
            NormalizationUtility.normalize(topic)

        let descriptor: FetchDescriptor<PlayedPairRecord>

        if topic.isEmpty {

            descriptor =
                FetchDescriptor<PlayedPairRecord>()

        } else {

            descriptor =
                FetchDescriptor<PlayedPairRecord>(
                    predicate: #Predicate {
                        $0.topic == normalizedTopic
                    }
                )
        }

        let records =
            (try? context.fetch(descriptor)) ?? []

        for record in records {
            context.delete(record)
        }

        do {

            try context.save()

            Self.logger.notice(
                "Cleared history for topic: \(topic.isEmpty ? "all" : topic)"
            )

        } catch {

            Self.logger.error(
                "Failed to clear history: \(String(describing: error))"
            )
        }
    }

    // MARK: - Count

    /// Returns the number of played pairs.
    ///
    /// Pass a topic to count only that topic.
    /// Pass an empty string to count all pairs.
    public func count(
        for topic: String = ""
    ) async -> Int {

        let context = ModelContext(container)

        if topic.isEmpty {

            let descriptor =
                FetchDescriptor<PlayedPairRecord>()

            return (
                try? context.fetchCount(descriptor)
            ) ?? 0
        }

        let normalizedTopic =
            NormalizationUtility.normalize(topic)

        let descriptor =
            FetchDescriptor<PlayedPairRecord>(
                predicate: #Predicate {
                    $0.topic == normalizedTopic
                }
            )

        return (
            try? context.fetchCount(descriptor)
        ) ?? 0
    }

    // MARK: - Topics

    /// Returns all topics that contain played pairs.
    public func topics() async -> [String] {

        let records = fetchRecordsForAllTopics()

        var distinctTopics = Set<String>()

        for record in records {
            distinctTopics.insert(record.topic)
        }

        return distinctTopics.sorted()
    }

    // MARK: - Private

    private func fetchRecords(
        for topic: String
    ) -> [PlayedPairRecord] {

        let context = ModelContext(container)

        let normalizedTopic =
            NormalizationUtility.normalize(topic)

        let descriptor =
            FetchDescriptor<PlayedPairRecord>(
                predicate: #Predicate {
                    $0.topic == normalizedTopic
                }
            )

        return (
            try? context.fetch(descriptor)
        ) ?? []
    }

    private func fetchRecordsForAllTopics()
        -> [PlayedPairRecord] {

        let context = ModelContext(container)

        let descriptor =
            FetchDescriptor<PlayedPairRecord>()

        return (
            try? context.fetch(descriptor)
        ) ?? []
    }
}
