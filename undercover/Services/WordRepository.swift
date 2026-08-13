//
//  WordRepository.swift
//  undercoverApp
//

import Foundation

public final class WordRepository: Sendable {

    private let database: [String: [WordPair]]
    private static let classifier = PairDifficultyClassifier()

    public var topics: [String] { database.keys.sorted() }

    public init() {
        guard
            let url  = Bundle.main.url(forResource: "words", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let db   = try? JSONDecoder().decode([String: [WordPair]].self, from: data)
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

    public func randomPair(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String> = []
    ) -> WordPair? {
        let normalised = Set(excluding.map { $0.lowercased() })

        var candidates = pairs(for: topic).filter { pair in
            !pair.civilian.localized(for: language).isEmpty
                && Self.classifier.classify(score: pair.similarity ?? 0.62) == difficulty
                && !normalised.contains(pair.trackingKey)
        }

        // Relax exclusion if nothing's left.
        if candidates.isEmpty {
            candidates = pairs(for: topic).filter {
                Self.classifier.classify(score: $0.similarity ?? 0.62) == difficulty
            }
        }

        return candidates.randomElement()
    }

    public func allPairs(for topic: String) -> [WordPair] { pairs(for: topic) }

    // MARK: - Private

    private func pairs(for topic: String) -> [WordPair] {
        topic.isEmpty ? database.values.flatMap { $0 } : (database[topic] ?? [])
    }
}
