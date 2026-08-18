//
//  LocalWordGenerator.swift
//  undercoverApp
//
//  Fully offline. Actor for Swift 6 safety.
//  Strategy: WordRepository first → adjacent difficulty bands → static vocabulary generation.
//

import Foundation

public actor LocalWordGenerator: WordGeneratorProtocol {

    public let generatorName = "Local (Offline)"
    public var isAvailable: Bool { true }

    private let repository = WordRepository()

    // MARK: - Protocol

    public func randomPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair {

        // 1. Try the requested difficulty first.
        if let pair = repository.randomPair(
            topic: topic,
            language: language,
            difficulty: difficulty,
            excluding: excluding
        ) {
            return pair
        }

        // 2. If nothing is available, relax the difficulty.
        for relaxedDifficulty in PairDifficulty.allCases
        where relaxedDifficulty != difficulty {

            if let pair = repository.randomPair(
                topic: topic,
                language: language,
                difficulty: relaxedDifficulty,
                excluding: excluding
            ) {
                return pair
            }
        }

        // 3. Nothing available.
        throw WordGeneratorError.noPairsAvailable
    }
}
