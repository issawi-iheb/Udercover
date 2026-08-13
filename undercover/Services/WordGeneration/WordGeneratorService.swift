//
//  WordGeneratorService.swift
//  undercoverApp
//
//  Actor that iterates the generator chain in priority order.
//  Each generator is itself an actor, so all cache access is data-race-free.
//

import Foundation

public actor WordGeneratorService {

    private let generators: [any WordGeneratorProtocol]

    public init(generators: [any WordGeneratorProtocol]) {
        self.generators = generators
    }

    // MARK: - Public

    public func randomPair(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) async throws -> WordPair {

        var lastError: Error = WordGeneratorError.noPairsAvailable

        for generator in generators {
            guard await generator.isAvailable else { continue }

            do {
                let pair = try await generator.randomPair(
                    topic:      topic,
                    language:   language,
                    difficulty: difficulty,
                    excluding:  excluding
                )
                let civ = pair.civilian.localized(for: language)
                let uc  = pair.undercover.localized(for: language)
                print("✅ [\(await generator.generatorName)] \(civ) / \(uc) [\(pair.difficulty.label)]")
                return pair
            } catch {
                print("⚠️ [\(await generator.generatorName)] \(error.localizedDescription)")
                lastError = error
            }
        }

        throw lastError
    }

    public func activeGeneratorName() async -> String {
        for generator in generators {
            if await generator.isAvailable { return await generator.generatorName }
        }
        return "None"
    }
}
