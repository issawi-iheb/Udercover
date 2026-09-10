//
//  WordGeneratorService.swift
//  undercoverApp
//
//  Orchestrates the generator chain.
//  Tries each generator in priority order until one succeeds.
//

import Foundation

/// Service that orchestrates a chain of word-pair generators.
///
/// Tries generators in priority order:
/// 1. Local (fast, deterministic, limited)
/// 2. LLM (slower, creative, unlimited)
///
/// Returns the first successful result.
public actor WordGeneratorService {

    private let generators: [any WordGeneratorProtocol]

    public init(generators: [any WordGeneratorProtocol]) {
        self.generators = generators
    }

    // MARK: - Local

    public func generateLocalPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair {

        guard let local = generators.first(
            where: {
                $0.kind == .local
            }
        ) else {
            throw WordGeneratorError.noPairsAvailable
        }

        guard await local.isAvailable else {
            throw WordGeneratorError.unavailable(
                "Local word generator is not available."
            )
        }

        return try await local.randomPair(
            topic: topic,
            language: language,
            difficulty: difficulty,
            excluding: excluding
        )
    }

    // MARK: - LLM

    public func generateBackgroundPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair {

        guard let llm = generators.first(
            where: {
                $0.kind == .background
            }
        ) else {
            throw WordGeneratorError.noPairsAvailable
        }

        guard await llm.isAvailable else {
            throw WordGeneratorError.unavailable(
                "Foundation Models is not available."
            )
        }

        return try await llm.randomPair(
            topic: topic,
            language: language,
            difficulty: difficulty,
            excluding: excluding
        )
    }
}
