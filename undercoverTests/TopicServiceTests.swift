import Testing
@testable import undercover
internal import Foundation

struct TopicServiceTests {

    // MARK: - Local Topics

    @Test
    func topics_returnsLocalTopics() async {

        // Given
        let localProvider = MockTopicProvider(
            topics: [
                GameTopic(
                    id: "animals",
                    name: "Animals",
                    source: .local
                ),
                GameTopic(
                    id: "fruits",
                    name: "Fruits",
                    source: .local
                )
            ]
        )

        let service = TopicService(
            providers: [localProvider]
        )

        // When
        let topics = await service.topics()

        // Then
        #expect(topics.map { $0.name } == [
            "Animals",
            "Fruits"
        ])

        #expect(
            topics.allSatisfy { $0.source == .local }
        )
    }

    // MARK: - AI Topics

    @Test
    func topics_returnsAiTopics() async {

        // Given
        let aiProvider = MockTopicProvider(
            topics: [
                GameTopic(
                    id: "animals",
                    name: "Animals",
                    source: .ai
                ),
                GameTopic(
                    id: "cars",
                    name: "Cars",
                    source: .ai
                )
            ]
        )

        let service = TopicService(
            providers: [aiProvider]
        )

        // When
        let topics = await service.topics()

        // Then
        #expect(topics.map { $0.name } == [
            "Animals",
            "Cars"
        ])

        #expect(
            topics.allSatisfy { $0.source == .ai }
        )
    }

    // MARK: - Merge

    @Test
    func topics_mergesAndDeduplicatesProviders() async {

        // Given
        let localProvider = MockTopicProvider(
            topics: [
                GameTopic(
                    id: "animals",
                    name: "Animals",
                    source: .local
                ),
                GameTopic(
                    id: "fruits",
                    name: "Fruits",
                    source: .local
                )
            ]
        )

        let aiProvider = MockTopicProvider(
            topics: [
                GameTopic(
                    id: "animals",
                    name: "Animals",
                    source: .ai
                ),
                GameTopic(
                    id: "cars",
                    name: "Cars",
                    source: .ai
                )
            ]
        )

        let service = TopicService(
            providers: [
                localProvider,
                aiProvider
            ]
        )

        // When
        let topics = await service.topics()

        // Then
        #expect(topics.map { $0.name } == [
            "Animals",
            "Cars",
            "Fruits"
        ])

        #expect(topics.count == 3)

        // Local provider comes first, so the local Animals
        // should win the duplicate.
        #expect(
            topics.first { $0.id == "animals" }?.source == .local
        )
    }

    // MARK: - Sorting

    @Test
    func topics_sortsResultAlphabeticallyByName() async {

        // Given
        let localProvider = MockTopicProvider(
            topics: [
                GameTopic(
                    id: "zebra-topic",
                    name: "Zebra Topic",
                    source: .local
                ),
                GameTopic(
                    id: "apple-topic",
                    name: "Apple Topic",
                    source: .local
                ),
                GameTopic(
                    id: "animals",
                    name: "Animals",
                    source: .local
                )
            ]
        )

        let service = TopicService(
            providers: [localProvider]
        )

        // When
        let topics = await service.topics()

        // Then
        #expect(topics.map { $0.name } == [
            "Animals",
            "Apple Topic",
            "Zebra Topic"
        ])
    }

    // MARK: - Cache

    @Test
    func topics_cachesResultAfterFirstCall() async {

        // Given
        let provider = CountingTopicProvider(
            topics: [
                GameTopic(
                    id: "animals",
                    name: "Animals",
                    source: .local
                )
            ]
        )

        let service = TopicService(
            providers: [provider]
        )

        // When
        let firstCall = await service.topics()
        let secondCall = await service.topics()

        // Then
        #expect(firstCall == secondCall)
        #expect(await provider.callCount == 1)
    }

    // MARK: - Empty

    @Test
    func topics_returnsEmptyWhenAllProvidersEmpty() async {

        // Given
        let localProvider = MockTopicProvider(topics: [])
        let aiProvider = MockTopicProvider(topics: [])

        let service = TopicService(
            providers: [
                localProvider,
                aiProvider
            ]
        )

        // When
        let topics = await service.topics()

        // Then
        #expect(topics.isEmpty)
    }
}

// MARK: - Test Doubles

private struct MockTopicProvider: TopicProvider {

    let topicsToReturn: [GameTopic]

    init(topics: [GameTopic]) {
        self.topicsToReturn = topics
    }

    func topics() async -> [GameTopic] {
        topicsToReturn
    }
}

private actor CountingTopicProvider: TopicProvider {

    let topicsToReturn: [GameTopic]
    private(set) var callCount = 0

    init(topics: [GameTopic]) {
        self.topicsToReturn = topics
    }

    func topics() async -> [GameTopic] {
        callCount += 1
        return topicsToReturn
    }
}
