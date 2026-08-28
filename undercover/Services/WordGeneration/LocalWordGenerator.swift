//
//  LocalWordGenerator.swift
//  undercoverApp
//
//  Fully offline generator. Actor for Swift 6 safety.
//  Uses NormalizationUtility for concept identity.
//  Strategy: WordRepository first → adjacent difficulty bands → fallback.
//

import Foundation

public actor LocalWordGenerator: WordGeneratorProtocol {

    public let generatorName = "Local (Offline)"
    public var isAvailable: Bool { true }

    private let repository = WordRepository()

    // MARK: - Game Lifecycle

    /// Call when a new game starts to reset session state.
    public func resetGame() {
        print("🔄 [Local] Reset for new game.")
    }

    // MARK: - Protocol

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

        if let pair = repository.randomPair(
            topic: topic,
            language: language,
            difficulty: difficulty,
            excluding: excluding
        ) {
            print("✅ [Local] Found pair")
            return pair
        }

        print("""
        ⚠️ [Local] No unused \(difficulty.rawValue) pairs available.
        → Falling back to next generator.
        """)

        throw WordGeneratorError.noPairsAvailable
    }
}
