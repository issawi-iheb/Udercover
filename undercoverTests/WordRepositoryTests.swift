//
//  WordRepositoryTests.swift
//  undercoverTests
//
import Testing
@testable import undercover

struct WordRepositoryTests {

    @Test
    func repositoryLoadsTopics() {
        let repository = WordRepository()

        let topics = repository.topics

        #expect(!topics.isEmpty)
    }

    @Test
    func topicsAreSorted() {
        let repository = WordRepository()

        let topics = repository.topics

        #expect(topics == topics.sorted())
    }

    @Test
    func allPairsReturnsPairsForExistingTopic() {
        let repository = WordRepository()

        let topics = repository.topics
        #expect(!topics.isEmpty)

        guard let topic = topics.first else {
            return
        }

        let pairs = repository.allPairs(for: topic)

        #expect(!pairs.isEmpty)
        #expect(pairs.allSatisfy { $0.topic == topic })
    }

    @Test
    func allPairsReturnsEmptyForUnknownTopic() {
        let repository = WordRepository()

        let pairs = repository.allPairs(for: "topic-that-does-not-exist")

        #expect(pairs.isEmpty)
    }

    @Test
    func allPairsReturnsAllPairsWhenTopicIsEmpty() {
        let repository = WordRepository()

        let pairs = repository.allPairs(for: "")

        #expect(!pairs.isEmpty)
    }

    @Test
    func randomPairReturnsPairForExistingTopic() {
        let repository = WordRepository()

        let topics = repository.topics
        #expect(!topics.isEmpty)

        guard let topic = topics.first else {
            return
        }

        let pair = repository.randomPair(
            topic: topic,
            language: .english,
            difficulty: .medium,
            excluding: []
        )

        #expect(pair != nil)
    }

    @Test
    func randomPairRespectsDifficulty() {
        let repository = WordRepository()

        let topics = repository.topics
        #expect(!topics.isEmpty)

        guard let topic = topics.first else {
            return
        }

        let pair = repository.randomPair(
            topic: topic,
            language: .english,
            difficulty: .medium,
            excluding: []
        )

        if let pair {
            #expect(pair.difficulty == .medium)
        }
    }

    @Test
    func randomPairReturnsNilForUnknownTopic() {
        let repository = WordRepository()

        let pair = repository.randomPair(
            topic: "topic-that-does-not-exist",
            language: .english,
            difficulty: .medium,
            excluding: []
        )

        #expect(pair == nil)
    }

    @Test
    func randomPairExcludesUsedConcepts() {
        let repository = WordRepository()

        let topics = repository.topics
        #expect(!topics.isEmpty)

        guard let topic = topics.first else {
            return
        }

        let pairs = repository.allPairs(for: topic)
        #expect(!pairs.isEmpty)

        guard let firstPair = pairs.first else {
            return
        }

        let civilian = firstPair.civilian.localized(for: .english)
        let undercover = firstPair.undercover.localized(for: .english)

        let pair = repository.randomPair(
            topic: topic,
            language: .english,
            difficulty: firstPair.difficulty,
            excluding: [
                civilian,
                undercover
            ]
        )

        if let pair {
            #expect(
                pair.civilian.localized(for: .english) != civilian
            )
            #expect(
                pair.civilian.localized(for: .english) != undercover
            )
            #expect(
                pair.undercover.localized(for: .english) != civilian
            )
            #expect(
                pair.undercover.localized(for: .english) != undercover
            )
        }
    }
}
