//
//  WordRepository.swift
//  undercoverApp
//
//  Single source of truth for offline word pairs.
//  Uses centralized NormalizationUtility for consistent concept identity.
//

import Foundation

public final class WordRepository: Sendable, TopicRepository {

    private let database: [String: [WordPair]]
    private nonisolated static let classifier = PairDifficultyClassifier()

    nonisolated public var topics: [String] {
        database.keys.sorted()
    }

    nonisolated public init() {
        guard
            let url = Bundle.main.url(forResource: "words", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let db = try? JSONDecoder().decode(
                [String: [WordPair]].self,
                from: data
            )
        else {
            print("⚠️ WordRepository: words.json missing or undecodable.")
            database = [:]
            return
        }

        database = db

        let total = db.values.map(\.count).reduce(0, +)
        print("✅ WordRepository: \(total) pairs across \(db.count) topics.")
    }

    nonisolated public func randomPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String> = []
    ) -> WordPair? {

        let normalizedExcluding = Set(
            excluding.map(NormalizationUtility.normalize)
        )

        let candidates = pairs(for: topic).filter { pair in

            guard !pair.civilian.localized(for: language).isEmpty else {
                return false
            }

            guard Self.classifier.classify(
                score: pair.similarity ?? 0.62
            ) == difficulty else {
                return false
            }

            let civilian = NormalizationUtility.normalize(
                pair.civilian.localized(for: language)
            )

            let undercover = NormalizationUtility.normalize(
                pair.undercover.localized(for: language)
            )

            guard !normalizedExcluding.contains(civilian),
                  !normalizedExcluding.contains(undercover)
            else {
                return false
            }

            return true
        }

        return candidates.randomElement()
    }

    nonisolated public func allPairs(for topic: String) -> [WordPair] {
        pairs(for: topic)
    }

    nonisolated func pairs(for topic: String) -> [WordPair] {
        if topic.isEmpty {
            return database.values.flatMap { $0 }
        }

        return database[topic] ?? []
    }
}
