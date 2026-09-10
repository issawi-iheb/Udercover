//
//  WordGeneratorServiceTests.swift
//  undercoverTests
//
//

import Testing
@testable import undercover

struct WordGeneratorServiceTests {

    // MARK: - Test Helpers

    private func makePair(
        civilian: String = "Cat",
        undercover: String = "Dog",
        topic: String = "animals"
    ) -> WordPair {
        WordPair(
            civilian: LocalizedWord(
                values: [
                    AppLanguage.english.rawValue: civilian
                ]
            ),
            undercover: LocalizedWord(
                values: [
                    AppLanguage.english.rawValue: undercover
                ]
            ),
            topic: topic,
            similarity: 0.62
        )
    }

    private actor MockGenerator: WordGeneratorProtocol {

        struct Request: Sendable, Equatable {
            let topic: String
            let language: AppLanguage
            let difficulty: PairDifficulty
            let excluding: Set<String>
        }

        let generatorName: String
        let kind: WordGeneratorKind
        let isAvailable: Bool

        private let result: Result<WordPair, WordGeneratorError>
        private(set) var requests: [Request] = []

        init(
            name: String = "Mock",
            kind: WordGeneratorKind,
            isAvailable: Bool = true,
            result: Result<WordPair, WordGeneratorError>
        ) {
            self.generatorName = name
            self.kind = kind
            self.isAvailable = isAvailable
            self.result = result
        }

        func randomPair(
            topic: String,
            language: AppLanguage,
            difficulty: PairDifficulty,
            excluding: Set<String>
        ) async throws -> WordPair {

            requests.append(
                Request(
                    topic: topic,
                    language: language,
                    difficulty: difficulty,
                    excluding: excluding
                )
            )

            return try result.get()
        }

        func recordedRequests() -> [Request] {
            requests
        }
    }

    // MARK: - Local

    @Test
    func generateLocalPair_returnsPairFromLocalGenerator() async throws {
        let expected = makePair()

        let local = MockGenerator(
            name: "Local",
            kind: .local,
            result: .success(expected)
        )

        let service = WordGeneratorService(
            generators: [local]
        )

        let result = try await service.generateLocalPair(
            topic: "animals",
            language: .english,
            difficulty: .medium,
            excluding: []
        )
        await MainActor.run {
            #expect(result == expected)
        }
    }

    @Test
    func generateLocalPair_throwsNoPairsAvailable_whenLocalGeneratorIsMissing() async {
        let background = MockGenerator(
            name: "LLM",
            kind: .background,
            result: .success(makePair())
        )

        let service = WordGeneratorService(
            generators: [background]
        )

        await #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            _ = try await service.generateLocalPair(
                topic: "animals",
                language: .english,
                difficulty: .medium,
                excluding: []
            )
        }

        let requests = await background.recordedRequests()
        #expect(requests.isEmpty)
    }

    @Test
    func generateLocalPair_throwsUnavailable_whenLocalGeneratorIsUnavailable() async {
        let local = MockGenerator(
            name: "Local",
            kind: .local,
            isAvailable: false,
            result: .success(makePair())
        )

        let service = WordGeneratorService(
            generators: [local]
        )

        await #expect(
            throws: WordGeneratorError.unavailable(
                "Local word generator is not available."
            )
        ) {
            _ = try await service.generateLocalPair(
                topic: "animals",
                language: .english,
                difficulty: .medium,
                excluding: []
            )
        }

        let requests = await local.recordedRequests()
        #expect(requests.isEmpty)
    }

    @Test
    func generateLocalPair_forwardsAllParameters() async throws {
        let local = MockGenerator(
            name: "Local",
            kind: .local,
            result: .success(makePair())
        )

        let service = WordGeneratorService(
            generators: [local]
        )

        let exclusions: Set<String> = [
            "cat",
            "dog",
            "new york"
        ]

        _ = try await service.generateLocalPair(
            topic: "animals",
            language: .english,
            difficulty: .hard,
            excluding: exclusions
        )

        let requests = await local.recordedRequests()

        #expect(requests.count == 1)

        let request = try #require(requests.first)

        #expect(request.topic == "animals")
        #expect(request.language == .english)
        #expect(request.difficulty == .hard)
        #expect(request.excluding == exclusions)
    }

    @Test
    func generateLocalPair_propagatesGeneratorError() async {
        let local = MockGenerator(
            name: "Local",
            kind: .local,
            result: .failure(.noPairsAvailable)
        )

        let service = WordGeneratorService(
            generators: [local]
        )

        await #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            _ = try await service.generateLocalPair(
                topic: "animals",
                language: .english,
                difficulty: .medium,
                excluding: []
            )
        }

        let requests = await local.recordedRequests()
        #expect(requests.count == 1)
    }

    // MARK: - Background / LLM

    @Test
    func generateBackgroundPair_returnsPairFromBackgroundGenerator() async throws {
        let expected = makePair(
            civilian: "Apple",
            undercover: "Orange",
            topic: "fruits"
        )

        let background = MockGenerator(
            name: "LLM",
            kind: .background,
            result: .success(expected)
        )

        let service = WordGeneratorService(
            generators: [background]
        )

        let result = try await service.generateBackgroundPair(
            topic: "fruits",
            language: .english,
            difficulty: .medium,
            excluding: []
        )
        await MainActor.run {
            #expect(result == expected)
        }

        
    }

    @Test
    func generateBackgroundPair_throwsNoPairsAvailable_whenBackgroundGeneratorIsMissing() async {
        let local = MockGenerator(
            name: "Local",
            kind: .local,
            result: .success(makePair())
        )

        let service = WordGeneratorService(
            generators: [local]
        )

        await #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            _ = try await service.generateBackgroundPair(
                topic: "animals",
                language: .english,
                difficulty: .medium,
                excluding: []
            )
        }

        let requests = await local.recordedRequests()
        #expect(requests.isEmpty)
    }

    @Test
    func generateBackgroundPair_throwsUnavailable_whenBackgroundGeneratorIsUnavailable() async {
        let background = MockGenerator(
            name: "LLM",
            kind: .background,
            isAvailable: false,
            result: .success(makePair())
        )

        let service = WordGeneratorService(
            generators: [background]
        )

        await #expect(
            throws: WordGeneratorError.unavailable(
                "Foundation Models is not available."
            )
        ) {
            _ = try await service.generateBackgroundPair(
                topic: "animals",
                language: .english,
                difficulty: .medium,
                excluding: []
            )
        }

        let requests = await background.recordedRequests()
        #expect(requests.isEmpty)
    }

    @Test
    func generateBackgroundPair_forwardsAllParameters() async throws {
        let background = MockGenerator(
            name: "LLM",
            kind: .background,
            result: .success(makePair())
        )

        let service = WordGeneratorService(
            generators: [background]
        )

        let exclusions: Set<String> = [
            "café",
            "new york"
        ]

        _ = try await service.generateBackgroundPair(
            topic: "food",
            language: .english,
            difficulty: .easy,
            excluding: exclusions
        )

        let requests = await background.recordedRequests()

        #expect(requests.count == 1)

        let request = try #require(requests.first)

        #expect(request.topic == "food")
        #expect(request.language == .english)
        #expect(request.difficulty == .easy)
        #expect(request.excluding == exclusions)
    }

    @Test
    func generateBackgroundPair_propagatesGeneratorError() async {
        let background = MockGenerator(
            name: "LLM",
            kind: .background,
            result: .failure(.parsingFailed("Invalid JSON"))
        )

        let service = WordGeneratorService(
            generators: [background]
        )

        await #expect(
            throws: WordGeneratorError.parsingFailed("Invalid JSON")
        ) {
            _ = try await service.generateBackgroundPair(
                topic: "animals",
                language: .english,
                difficulty: .medium,
                excluding: []
            )
        }

        let requests = await background.recordedRequests()
        #expect(requests.count == 1)
    }

    // MARK: - Generator Selection

    @Test
    func generateLocalPair_usesFirstLocalGenerator() async throws {
        let firstPair = makePair(
            civilian: "Cat",
            undercover: "Dog"
        )

        let secondPair = makePair(
            civilian: "Lion",
            undercover: "Tiger"
        )

        let firstLocal = MockGenerator(
            name: "First Local",
            kind: .local,
            result: .success(firstPair)
        )

        let secondLocal = MockGenerator(
            name: "Second Local",
            kind: .local,
            result: .success(secondPair)
        )

        let service = WordGeneratorService(
            generators: [
                firstLocal,
                secondLocal
            ]
        )

        let result = try await service.generateLocalPair(
            topic: "animals",
            language: .english,
            difficulty: .medium,
            excluding: []
        )
        await MainActor.run {
            #expect(result == firstPair)
        }
        let firstRequests = await firstLocal.recordedRequests()
        let secondRequests = await secondLocal.recordedRequests()

        #expect(firstRequests.count == 1)
        #expect(secondRequests.isEmpty)
    }

    @Test
    func generateBackgroundPair_usesFirstBackgroundGenerator() async throws {
        let firstPair = makePair(
            civilian: "Apple",
            undercover: "Orange",
            topic: "fruits"
        )

        let secondPair = makePair(
            civilian: "Pear",
            undercover: "Peach",
            topic: "fruits"
        )

        let firstBackground = MockGenerator(
            name: "First LLM",
            kind: .background,
            result: .success(firstPair)
        )

        let secondBackground = MockGenerator(
            name: "Second LLM",
            kind: .background,
            result: .success(secondPair)
        )

        let service = WordGeneratorService(
            generators: [
                firstBackground,
                secondBackground
            ]
        )

        let result = try await service.generateBackgroundPair(
            topic: "fruits",
            language: .english,
            difficulty: .medium,
            excluding: []
        )
        
        await MainActor.run {
            #expect(result == firstPair)
        }
        let firstRequests = await firstBackground.recordedRequests()
        let secondRequests = await secondBackground.recordedRequests()

        #expect(firstRequests.count == 1)
        #expect(secondRequests.isEmpty)
    }
}
