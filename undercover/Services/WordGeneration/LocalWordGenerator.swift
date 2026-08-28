//
//  LocalWordGenerator.swift
//  undercoverApp
//
//  Fully offline generator.
//

import Foundation

public actor LocalWordGenerator: WordGeneratorProtocol {

    public let generatorName =
        "Local (Offline)"

    public var isAvailable: Bool {
        true
    }

    private let repository =
        WordRepository()

    // MARK: - Game Lifecycle

    public func resetGame() {
        print("🔄 [Local] Reset for new game.")
    }

    // MARK: - Generator

    public func randomPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair {

        print("""
        🧠 [Local]
        Topic: \(topic)
        Difficulty: \(difficulty.rawValue)
        Exclusions: \(excluding.count)
        """)

        if let pair =
            repository.randomPair(
                topic: topic,
                language: language,
                difficulty: difficulty,
                excluding: excluding
            ) {

            print("✅ [Local] Found pair")

            return pair
        }

        print("""
        ⚠️ [Local] No unused \(difficulty.rawValue) pairs.
        → Falling back to next generator.
        """)

        throw WordGeneratorError.noPairsAvailable
    }
}
