//
//  WordPairProviderTests.swift
//  undercoverTests
//
//
import Testing
@testable import undercover

@MainActor
struct WordPairProviderTests {

    // MARK: - Fixtures

    private func makePair(
        civilian: String,
        undercover: String,
        topic: String,
        similarity: Double = 0.62
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
            similarity: similarity
        )
    }

    private func makeStore() -> PlayedPairStore {
        PlayedPairStore(isStoredInMemoryOnly: true)
    }

    // MARK: - Test Doubles

    private actor MockWordGenerator: WordGeneratorProtocol {

        enum Behavior: Sendable {
            case success(WordPair)
            case failure(WordGeneratorError)
        }

        struct Request: Sendable, Equatable {
            let topic: String
            let language: AppLanguage
            let difficulty: PairDifficulty
            let excluding: Set<String>
        }

        let generatorName: String
        let kind: WordGeneratorKind
        let isAvailable: Bool

        private let behavior: Behavior
        private var requests: [Request] = []

        init(
            name: String,
            kind: WordGeneratorKind,
            isAvailable: Bool = true,
            behavior: Behavior
        ) {
            self.generatorName = name
            self.kind = kind
            self.isAvailable = isAvailable
            self.behavior = behavior
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

            switch behavior {
            case .success(let pair):
                return pair

            case .failure(let error):
                throw error
            }
        }

        func recordedRequests() -> [Request] {
            requests
        }
    }

    private actor RequestSequenceGenerator: WordGeneratorProtocol {

        let generatorName = "Sequence"
        let kind = WordGeneratorKind.local
        let isAvailable = true

        private var pairs: [WordPair]
        private var requests: [MockWordGenerator.Request] = []

        init(pairs: [WordPair]) {
            self.pairs = pairs
        }

        func randomPair(
            topic: String,
            language: AppLanguage,
            difficulty: PairDifficulty,
            excluding: Set<String>
        ) async throws -> WordPair {

            requests.append(
                MockWordGenerator.Request(
                    topic: topic,
                    language: language,
                    difficulty: difficulty,
                    excluding: excluding
                )
            )

            guard !pairs.isEmpty else {
                throw WordGeneratorError.noPairsAvailable
            }

            return pairs.removeFirst()
        }

        func recordedRequests() -> [MockWordGenerator.Request] {
            requests
        }
    }

    private func makeProvider(
        localBehavior: MockWordGenerator.Behavior,
        llmBehavior: MockWordGenerator.Behavior
    ) -> (
        provider: WordPairProvider,
        local: MockWordGenerator,
        llm: MockWordGenerator
    ) {
        let local = MockWordGenerator(
            name: "Local",
            kind: .local,
            behavior: localBehavior
        )

        let llm = MockWordGenerator(
            name: "LLM",
            kind: .background,
            behavior: llmBehavior
        )

        let service = WordGeneratorService(
            generators: [local, llm]
        )

        let provider = WordPairProvider(
            generatorService: service,
            pairStore: makeStore(),
            nextPairMutex: AsyncMutex()
        )

        return (
            provider: provider,
            local: local,
            llm: llm
        )
    }

    // MARK: - Basic Generation

    @Test
    func nextPair_returnsLocalPair_whenLocalGenerationSucceeds()
    async throws {

        let expected = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let system = makeProvider(
            localBehavior: .success(expected),
            llmBehavior: .failure(.noPairsAvailable)
        )

        let result = try await system.provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        #expect(result == expected)

        let requests = await system.local.recordedRequests()

        #expect(requests.count == 1)
        #expect(requests[0].topic == "animals")
        #expect(requests[0].language == .english)
        #expect(requests[0].difficulty == .medium)
    }

    @Test
    func nextPair_returnsLLMPair_whenLocalGenerationFails()
    async throws {

        let expected = makePair(
            civilian: "Apple",
            undercover: "Orange",
            topic: "fruits"
        )

        let system = makeProvider(
            localBehavior: .failure(.noPairsAvailable),
            llmBehavior: .success(expected)
        )

        let result = try await system.provider.nextPair(
            playerCount: 4,
            topic: "fruits",
            language: .english,
            difficulty: .medium
        )

        #expect(result == expected)

        let localRequests = await system.local.recordedRequests()
        let llmRequests = await system.llm.recordedRequests()

        #expect(localRequests.count == 1)
        #expect(!llmRequests.isEmpty)
    }

    @Test
    func nextPair_throwsUnableToProvidePair_whenAllGeneratorsFail()
    async {

        let system = makeProvider(
            localBehavior: .failure(.noPairsAvailable),
            llmBehavior: .failure(.noPairsAvailable)
        )

        await #expect(
            throws: WordPairProviderError.unableToProvidePair
        ) {
            _ = try await system.provider.nextPair(
                playerCount: 4,
                topic: "animals",
                language: .english,
                difficulty: .medium
            )
        }
    }

    @Test
    func nextPair_throws_whenPlayerCountIsBelowMinimum()
    async {

        let pair = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let system = makeProvider(
            localBehavior: .success(pair),
            llmBehavior: .success(pair)
        )

        await #expect(
            throws: WordPairProviderError.unableToProvidePair
        ) {
            _ = try await system.provider.nextPair(
                playerCount: 2,
                topic: "animals",
                language: .english,
                difficulty: .medium
            )
        }

        let localRequests = await system.local.recordedRequests()
        let llmRequests = await system.llm.recordedRequests()

        #expect(localRequests.isEmpty)
        #expect(llmRequests.isEmpty)
    }

    // MARK: - Request Forwarding

    @Test
    func nextPair_forwardsAllGenerationParameters()
    async throws {

        let pair = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let system = makeProvider(
            localBehavior: .success(pair),
            llmBehavior: .failure(.noPairsAvailable)
        )

        _ = try await system.provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .hard
        )

        let requests = await system.local.recordedRequests()

        #expect(requests.count == 1)

        let request = requests[0]

        #expect(request.topic == "animals")
        #expect(request.language == .english)
        #expect(request.difficulty == .hard)
    }

    // MARK: - Cache

    @Test
    func nextPair_returnsPreparedPair_withoutGeneratingAnotherLocalPair()
    async throws {

        let first = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let second = makePair(
            civilian: "Lion",
            undercover: "Tiger",
            topic: "animals"
        )

        let generator = RequestSequenceGenerator(
            pairs: [first, second]
        )

        let llm = MockWordGenerator(
            name: "LLM",
            kind: .background,
            behavior: .failure(.noPairsAvailable)
        )

        let provider = WordPairProvider(
            generatorService: WordGeneratorService(
                generators: [generator, llm]
            ),
            pairStore: makeStore(),
            nextPairMutex: AsyncMutex()
        )

        let firstResult = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        #expect(firstResult == first)

        let requestsAfterFirst = await generator.recordedRequests()
        #expect(requestsAfterFirst.count == 1)

        let secondResult = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        #expect(secondResult == second)

        let requestsAfterSecond = await generator.recordedRequests()

        #expect(requestsAfterSecond.count >= 2)
    }

    @Test
    func nextPair_doesNotUsePairThatWasAlreadyPlayed()
    async throws {

        let first = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let second = makePair(
            civilian: "Lion",
            undercover: "Tiger",
            topic: "animals"
        )

        let generator = RequestSequenceGenerator(
            pairs: [first, second]
        )

        let llm = MockWordGenerator(
            name: "LLM",
            kind: .background,
            behavior: .failure(.noPairsAvailable)
        )

        let store = makeStore()

        let provider = WordPairProvider(
            generatorService: WordGeneratorService(
                generators: [generator, llm]
            ),
            pairStore: store,
            nextPairMutex: AsyncMutex()
        )

        _ = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        let secondResult = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        #expect(secondResult == second)
    }

    // MARK: - Exclusions

    @Test
    func nextPair_passesPlayedConceptsAsExclusions()
    async throws {

        let first = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let second = makePair(
            civilian: "Lion",
            undercover: "Tiger",
            topic: "animals"
        )

        let generator = RequestSequenceGenerator(
            pairs: [first, second]
        )

        let llm = MockWordGenerator(
            name: "LLM",
            kind: .background,
            behavior: .failure(.noPairsAvailable)
        )

        let provider = WordPairProvider(
            generatorService: WordGeneratorService(
                generators: [generator, llm]
            ),
            pairStore: makeStore(),
            nextPairMutex: AsyncMutex()
        )

        _ = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        _ = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        let requests = await generator.recordedRequests()

        #expect(requests.count >= 2)

        let secondRequest = requests[1]

        #expect(
            secondRequest.excluding.contains(
                NormalizationUtility.normalize("Cat")
            )
        )

        #expect(
            secondRequest.excluding.contains(
                NormalizationUtility.normalize("Dog")
            )
        )
    }

    // MARK: - Reset

    @Test
    func reset_allowsFreshGeneration()
    async throws {

        let first = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let second = makePair(
            civilian: "Lion",
            undercover: "Tiger",
            topic: "animals"
        )

        let generator = RequestSequenceGenerator(
            pairs: [first, second]
        )

        let llm = MockWordGenerator(
            name: "LLM",
            kind: .background,
            behavior: .failure(.noPairsAvailable)
        )

        let provider = WordPairProvider(
            generatorService: WordGeneratorService(
                generators: [generator, llm]
            ),
            pairStore: makeStore(),
            nextPairMutex: AsyncMutex()
        )

        let firstResult = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        provider.reset()

        let secondResult = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        #expect(firstResult == first)
        #expect(secondResult == second)
    }

    // MARK: - Configuration

    @Test
    func nextPair_restartsPreparation_whenTopicChanges()
    async throws {

        let animalsPair = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let fruitsPair = makePair(
            civilian: "Apple",
            undercover: "Orange",
            topic: "fruits"
        )

        let generator = RequestSequenceGenerator(
            pairs: [animalsPair, fruitsPair]
        )

        let llm = MockWordGenerator(
            name: "LLM",
            kind: .background,
            behavior: .failure(.noPairsAvailable)
        )

        let provider = WordPairProvider(
            generatorService: WordGeneratorService(
                generators: [generator, llm]
            ),
            pairStore: makeStore(),
            nextPairMutex: AsyncMutex()
        )

        let first = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        #expect(first == animalsPair)

        let second = try await provider.nextPair(
            playerCount: 4,
            topic: "fruits",
            language: .english,
            difficulty: .medium
        )

        #expect(second == fruitsPair)
    }

    @Test
    func nextPair_restartsPreparation_whenDifficultyChanges()
    async throws {

        let mediumPair = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals",
            similarity: 0.62
        )

        let hardPair = makePair(
            civilian: "Lion",
            undercover: "Tiger",
            topic: "animals",
            similarity: 0.52
        )

        let generator = RequestSequenceGenerator(
            pairs: [mediumPair, hardPair]
        )

        let llm = MockWordGenerator(
            name: "LLM",
            kind: .background,
            behavior: .failure(.noPairsAvailable)
        )

        let provider = WordPairProvider(
            generatorService: WordGeneratorService(
                generators: [generator, llm]
            ),
            pairStore: makeStore(),
            nextPairMutex: AsyncMutex()
        )

        let first = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )

        #expect(first == mediumPair)

        let second = try await provider.nextPair(
            playerCount: 4,
            topic: "animals",
            language: .english,
            difficulty: .hard
        )

        #expect(second == hardPair)
    }
    
    @Test
    func nextPair_rejectsPlayerCountsBelowThree() async {
        let pair = makePair(
            civilian: "Cat",
            undercover: "Dog",
            topic: "animals"
        )

        let system = makeProvider(
            localBehavior: .success(pair),
            llmBehavior: .success(pair)
        )

        await #expect(
            throws: WordPairProviderError.unableToProvidePair
        ) {
            _ = try await system.provider.nextPair(
                playerCount: 2,
                topic: "animals",
                language: .english,
                difficulty: .medium
            )
        }
    }
}
