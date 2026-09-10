import Testing
@testable import undercover

struct LocalTopicProviderTests {

    @Test func topics_returnsRepositoryTopics() async {
        // Given: LocalTopicProvider (uses its internal WordRepository)
        let provider = await LocalTopicProvider()

        // When: Getting topics
        let topics = await provider.topics()

        // Then: Should match what the internal repository returns
        // Note: This will use the test words.json we placed in the test target
        let expectedTopics = await WordRepository().topics
        #expect(topics == expectedTopics)
    }

    @Test func topics_returnsNonEmptyListWithTestData() async {
        // Given: LocalTopicProvider
        let provider = await LocalTopicProvider()

        // When: Getting topics
        let topics = await provider.topics()

        // Then: Should have topics from our test data
        #expect(!topics.isEmpty)
        #expect(topics.contains("animals"))
        #expect(topics.contains("fruits"))
        #expect(topics.count == 35)
    }
}
