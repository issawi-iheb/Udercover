//
//  WordRepository.swift
//  undercoverApp
//
//  Single source of truth for offline word pairs.
//  Uses centralized NormalizationUtility for consistent concept identity.
//

import Foundation

public final class WordRepository: Sendable {

    private let database: [String: [WordPair]]
    private static let classifier = PairDifficultyClassifier()

    public var topics: [String] {
        database.keys.sorted()
    }

    // MARK: - Init

    public init() {
        guard
            let url = Bundle.main.url(forResource: "words", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let db = try? JSONDecoder().decode([String: [WordPair]].self, from: data)
        else {
            print("⚠️ WordRepository: words.json missing or undecodable.")
            database = [:]
            return
        }

        database = db

        let total = db.values.map(\.count).reduce(0, +)
        print("✅ WordRepository: \(total) pairs across \(db.count) topics.")
    }

    // MARK: - Public API

    /// Get a random pair for the given topic, language, and difficulty.
    /// Filters out concepts in the exclusion set.
    public func randomPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String> = []
    ) -> WordPair? {

        // Normalize exclusions using centralized utility
        let normalizedExcluding = Set(
            excluding.map(NormalizationUtility.normalize)
        )

        let candidates = pairs(for: topic).filter { pair in
            
            // 1. Must have translation for requested language
            guard !pair.civilian.localized(for: language).isEmpty else {
                return false
            }

            // 2. Must match requested difficulty
            guard Self.classifier.classify(score: pair.similarity ?? 0.62) == difficulty else {
                return false
            }

            // 3. Neither concept can be in exclusion set (CRITICAL)
            let civilian = NormalizationUtility.normalize(
                pair.civilian.values["en"]
            )
            let undercover = NormalizationUtility.normalize(
                pair.undercover.values["en"]
            )

            guard !normalizedExcluding.contains(civilian),
                  !normalizedExcluding.contains(undercover) else {
                print("""
                🚫 [Repository] Excluded: \(civilian) / \(undercover)
                """)
                return false
            }

            return true
        }

        return candidates.randomElement()
    }

    /// Get all pairs for a topic (used by UI to show stats).
    public func allPairs(for topic: String) -> [WordPair] {
        pairs(for: topic)
    }

    // MARK: - Private

    private func pairs(for topic: String) -> [WordPair] {
        if topic.isEmpty {
            return database.values.flatMap { $0 }
        }
        return database[topic] ?? []
    }
}
