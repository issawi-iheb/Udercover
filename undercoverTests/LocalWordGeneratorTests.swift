//
//  LocalWordGeneratorTests.swift
//  undercoverTests
//
//  Created by Iheb on 09/09/2026.
//

import Testing
@testable import undercover

struct LocalWordGeneratorTests {

    // MARK: - Metadata

    @Test
    func generator_hasExpectedMetadata() async {
        let generator = LocalWordGenerator()

        let name = await generator.generatorName
        let kind = await generator.kind
        let isAvailable = await generator.isAvailable

        #expect(name == "Local (Offline)")
        #expect(kind == .local)
        #expect(isAvailable == true)
    }

    // MARK: - Generation

    @Test
    func randomPair_returnsPairWhenAvailable() async throws {
        let generator = LocalWordGenerator()

        let pair = try await generator.randomPair(
            topic: "animals",
            language: .english,
            difficulty: .medium,
            excluding: []
        )

        await #expect(!pair.civilian.localized(for: .english).isEmpty)
        await #expect(!pair.undercover.localized(for: .english).isEmpty)
        #expect(pair.topic == "animals")
        #expect(pair.difficulty == .medium)
    }


    // MARK: - Errors

    @Test
    func randomPair_throwsNoPairsAvailableWhenNothingMatches() async {
        let generator = LocalWordGenerator()

        await #expect(
            performing: {
                try await generator.randomPair(
                    topic: "TopicThatDefinitelyDoesNotExist",
                    language: .english,
                    difficulty: .easy,
                    excluding: []
                )
            },
            throws: { error in
                guard let error = error as? WordGeneratorError else {
                    return false
                }

                return error == .noPairsAvailable
            }
        )
    }

    // MARK: - Lifecycle

    @Test
    func resetGame_doesNotThrow() async {
        let generator = LocalWordGenerator()

        await generator.resetGame()

        #expect(true)
    }
}
