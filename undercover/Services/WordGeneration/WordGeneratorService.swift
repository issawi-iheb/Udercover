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

    /// Get a word pair by trying each generator in sequence.
    ///
    /// - Parameters:
    ///   - topic: Topic/category for the pair
    ///   - language: Requested language
    ///   - difficulty: Requested difficulty (easy/medium/hard)
    ///   - excluding: Set of already-used concepts (normalized)
    ///
    /// - Returns: First successful WordPair
    /// - Throws: Last error if all generators fail
    public func randomPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair {

        var lastError: Error = WordGeneratorError.noPairsAvailable

        for generator in generators {
            guard await generator.isAvailable else {
                print("⏭️ [\(await generator.generatorName)] Not available, skipping")
                continue
            }

            do {
                let pair = try await generator.randomPair(
                    topic: topic,
                    language: language,
                    difficulty: difficulty,
                    excluding: excluding
                )

                print("""
                ✅ [\(await generator.generatorName)] Success
                """)

                return pair

            } catch {
                if error is CancellationError {
                    throw error
                }
                print("""
                ⚠️ [\(await generator.generatorName)] Failed: \(error.localizedDescription)
                """)
                lastError = error
            }
        }

        throw lastError
    }

    /// Get the name of the first available generator (for UI/debug).
    public func activeGeneratorName() async -> String {
        for generator in generators {
            if await generator.isAvailable {
                return await generator.generatorName
            }
        }
        return "None"
    }
}
