//
//  PlayedPairStoreTests.swift
//  undercoverTests
//
import Testing
@testable import undercover

struct PlayedPairStoreTests {

    @Test
    func newStoreHasEmptyHistory() async {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        let count = await store.count()

        #expect(count == 0)
    }

    @Test
    func markAsPlayedIncreasesCount() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let count = await store.count()

        #expect(count == 1)
    }

    @Test
    func markAsPlayedStoresPairForTopic() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let count = await store.count(for: "animals")

        #expect(count == 1)
    }

    @Test
    func differentTopicsHaveIndependentCounts() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        try await store.markAsPlayed(
            civilian: "Car",
            undercover: "Train",
            topic: "transport"
        )

        let animalsCount = await store.count(for: "animals")
        let transportCount = await store.count(for: "transport")

        #expect(animalsCount == 1)
        #expect(transportCount == 1)
        #expect(await store.count() == 2)
    }

    @Test
    func usedConceptsReturnsBothWords() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let concepts = await store.usedConcepts(for: "animals")

        #expect(concepts.contains("cat"))
        #expect(concepts.contains("tiger"))
    }

    @Test
    func canUseWordsReturnsFalseForPlayedPair() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let canUse = await store.canUseWords(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        #expect(!canUse)
    }

    @Test
    func canUseWordsReturnsFalseWhenCivilianConceptWasAlreadyUsed() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let canUse = await store.canUseWords(
            civilian: "Cat",
            undercover: "Lion",
            topic: "animals"
        )

        #expect(!canUse)
    }

    @Test
    func canUseWordsReturnsFalseWhenUndercoverConceptWasAlreadyUsed() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let canUse = await store.canUseWords(
            civilian: "Dog",
            undercover: "Tiger",
            topic: "animals"
        )

        #expect(!canUse)
    }

    @Test
    func canUseWordsReturnsTrueForUnusedPair() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let canUse = await store.canUseWords(
            civilian: "Dog",
            undercover: "Lion",
            topic: "animals"
        )

        #expect(canUse)
    }

    @Test
    func conceptsAreScopedToTopic() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        let canUseInAnimals = await store.canUseWords(
            civilian: "Cat",
            undercover: "Lion",
            topic: "animals"
        )

        let canUseInAnotherTopic = await store.canUseWords(
            civilian: "Cat",
            undercover: "Lion",
            topic: "nature"
        )

        #expect(!canUseInAnimals)
        #expect(canUseInAnotherTopic)
    }

    @Test
    func topicsReturnsDistinctTopics() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        try await store.markAsPlayed(
            civilian: "Dog",
            undercover: "Lion",
            topic: "animals"
        )

        try await store.markAsPlayed(
            civilian: "Car",
            undercover: "Train",
            topic: "transport"
        )

        let topics = await store.topics()

        #expect(topics.count == 2)
        #expect(topics.contains("animals"))
        #expect(topics.contains("transport"))
    }

    @Test
    func clearHistoryForTopicOnlyClearsThatTopic() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        try await store.markAsPlayed(
            civilian: "Car",
            undercover: "Train",
            topic: "transport"
        )

        await store.clearHistory(for: "animals")

        let animalsCount = await store.count(for: "animals")
        let transportCount = await store.count(for: "transport")

        #expect(animalsCount == 0)
        #expect(transportCount == 1)
    }

    @Test
    func clearHistoryWithoutTopicClearsEverything() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "animals"
        )

        try await store.markAsPlayed(
            civilian: "Car",
            undercover: "Train",
            topic: "transport"
        )

        await store.clearHistory()

        let count = await store.count()

        #expect(count == 0)
    }

    @Test
    func topicNormalizationIsConsistent() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: "Cat",
            undercover: "Tiger",
            topic: "Animals"
        )

        let count = await store.count(for: "ANIMALS")

        #expect(count == 1)
    }

    @Test
    func wordNormalizationIsConsistent() async throws {
        let store = PlayedPairStore(isStoredInMemoryOnly: true)

        try await store.markAsPlayed(
            civilian: " Red Apple ",
            undercover: "Green Apple",
            topic: "food"
        )

        let canUse = await store.canUseWords(
            civilian: "red apple",
            undercover: "Banana",
            topic: "food"
        )

        #expect(!canUse)
    }
}
