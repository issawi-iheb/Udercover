import Testing
@testable import undercover

struct LocalTopicProviderTests {

    private struct MockTopicRepository: TopicRepository {
        let topics: [String]
    }

    @Test
    func topics_returnsRepositoryTopicsAsLocalGameTopics() async {
        // Given
        let repository = MockTopicRepository(
            topics: ["animals", "fruits", "Science Fiction"]
        )

        let provider = LocalTopicProvider(repository: repository)

        // When
        let topics = await provider.topics()

        // Then
        #expect(topics.count == 3)
        #expect(topics.contains {
            $0.id == "animals" &&
            $0.name == "Animals" &&
            $0.source == .local
        })

        #expect(topics.contains {
            $0.id == "fruits" &&
            $0.name == "Fruits" &&
            $0.source == .local
        })

        #expect(topics.contains {
            $0.id == "science-fiction" &&
            $0.name == "Science Fiction" &&
            $0.source == .local
        })
    }

    @Test
    func topics_returnsEmptyWhenRepositoryIsEmpty() async {
        // Given
        let repository = MockTopicRepository(topics: [])
        let provider = LocalTopicProvider(repository: repository)

        // When
        let topics = await provider.topics()

        // Then
        #expect(topics.isEmpty)
    }

    @Test
    func topics_trimsAndNormalizesTopicNames() async {
        // Given
        let repository = MockTopicRepository(
            topics: [
                "  Animals  ",
                "Science Fiction",
                "Café"
            ]
        )

        let provider = LocalTopicProvider(repository: repository)

        // When
        let topics = await provider.topics()

        // Then
        #expect(topics.contains {
            $0.id == "animals" &&
            $0.name == "Animals"
        })

        #expect(topics.contains {
            $0.id == "science-fiction" &&
            $0.name == "Science Fiction"
        })

        #expect(topics.contains {
            $0.id == "cafe" &&
            $0.name == "Café"
        })
    }
}
