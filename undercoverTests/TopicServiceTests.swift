import Testing
@testable import undercover
internal import Foundation

@MainActor
struct TopicServiceTests {

    // MARK: - Local Topics

    @Test
    func topics_returnsLocalTopicsWhenNoAIProvider() async {

        // Given
        let repository =  WordRepository()

        let service = TopicService(
            repository: repository,
            aiProvider: nil
        )

        // When
        let topics = await service.topics()

        // Then
        let expectedTopics =  repository.topics
            .map { $0.capitalized }
            .sorted()

        #expect(topics.map { $0.name } == expectedTopics)
        #expect(topics.allSatisfy { $0.source == .local })
    }

    // MARK: - AI Topics

    @Test
    func topics_returnsAiTopicsWhenNoLocalTopics() async {

        // Given
        let repository = EmptyTopicRepository()

        let aiProvider = MockAIProvider(
            topics: [
                "Animals",
                "Cars"
            ]
        )

        let service = TopicService(
            repository: repository,
            aiProvider: aiProvider
        )

        // When
        let topics = await service.topics()

        // Then
        #expect(
            topics.map { $0.name } == [
                "Animals",
                "Cars"
            ]
        )

        #expect(
            topics.allSatisfy { $0.source == .ai }
        )
    }

    // MARK: - Merge

    @Test
    func topics_mergesAndDeduplicatesLocalAndAiTopics() async {

        // Given
        let aiProvider = MockAIProvider(
            topics: [
                "Animals",
                "Cars"
            ]
        )

        let service =  TopicService(
            repository: WordRepository(),
            aiProvider: aiProvider
        )

        // When
        let topics = await service.topics()

        // Then
        let expected = ["Animals", "Anime", "Anime_Extra", "Architecture", "Art", "Basketball", "Board Games", "Books", "Brands", "Cars", "Cartoons", "Celebrities", "Cities", "Comedy", "Countries", "Famous Places", "Fashion", "Food", "Football", "Fruits", "History", "Internet Culture", "Jobs", "Movies", "Music", "Mythology", "Professions", "Science", "Space", "Sports", "Sports Teams", "Technology", "Television", "Transport", "Video Games"]

        #expect(topics.map { $0.name } == expected)
    }

    // MARK: - Sorting

    @Test
    func topics_sortsResultAlphabeticallyByName() async {

        // Given
        let aiProvider = MockAIProvider(
            topics: [
                "Zebra Topic",
                "Apple Topic"
            ]
        )

        let service =  TopicService(
            repository: WordRepository(),
            aiProvider: aiProvider
        )

        // When
        let topics = await service.topics()

        // Then
        let topicNames = await MainActor.run {
            topics.map { $0.name }
        }

        #expect(topicNames == topicNames.sorted())
        #expect(topicNames.first == "Animals")
        #expect(topicNames.last == "Zebra Topic")
    }

    // MARK: - Cache

    @Test
    func topics_cachesResultAfterFirstCall() async {

        // Given
        let repository =  WordRepository()
        let service = TopicService(
            repository: repository,
            aiProvider: nil
        )

        // When
        let firstCall = await service.topics()
        let secondCall = await service.topics()

        // Then
        #expect(firstCall == secondCall)
    }

    // MARK: - Empty

    @Test
    func topics_returnsEmptyWhenBothProvidersEmpty() async {

        // Given
        let repository = EmptyTopicRepository()
        let aiProvider = EmptyAIProvider()

        let service = TopicService(
            repository: repository,
            aiProvider: aiProvider
        )

        // When
        let topics = await service.topics()

        // Then
        #expect(topics.isEmpty)
    }
}

// MARK: - Test Doubles

private struct EmptyTopicRepository: TopicRepository {

    let topics: [String] = []
}

private struct MockAIProvider: TopicProvider {

    let topicsToReturn: [String]

    init(topics: [String]) {
        self.topicsToReturn = topics
    }

    func topics() async -> [String] {
        topicsToReturn
    }
}

private struct EmptyAIProvider: TopicProvider {

    func topics() async -> [String] {
        []
    }
}
