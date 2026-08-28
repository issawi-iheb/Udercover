//
//  TopicService.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation

public actor TopicService {

    private let repository: WordRepository
    private let aiProvider: FoundationModelsTopicProvider?
    private var cachedTopics: [GameTopic] = []

    public init(
        repository: WordRepository = WordRepository(),
        aiProvider: FoundationModelsTopicProvider? = nil
    ) {
        self.repository = repository
        self.aiProvider = aiProvider
    }

    /// Get all topics (cached after first fetch).
    public func topics() async -> [GameTopic] {
        if !cachedTopics.isEmpty {
            return cachedTopics
        }

        // Local topics from repository
        let localTopics = repository.topics.map { topic in
            GameTopic(
                id: normalizeForID(topic),
                name: topic.capitalized,
                source: .local
            )
        }

        // AI-generated topics (if provider available)
        var aiTopics: [GameTopic] = []
        if let provider = aiProvider {
            let aiNames = await provider.topics()
            aiTopics = aiNames.map { topic in
                GameTopic(
                    id: normalizeForID(topic),
                    name: topic.capitalized,
                    source: .ai
                )
            }
        }

        // Merge and deduplicate
        let result = mergeTopics(localTopics, aiTopics)

        print("""
        📚 [TopicService] Loaded \(result.count) topics
        """)

        cachedTopics = result
        return result
    }

    // MARK: - Private

    private func mergeTopics(
        _ first: [GameTopic],
        _ second: [GameTopic]
    ) -> [GameTopic] {

        var result: [GameTopic] = []
        var seen = Set<String>()

        for topic in first + second {
            let id = topic.id

            guard !seen.contains(id) else { continue }

            seen.insert(id)
            result.append(topic)
        }

        return result.sorted { $0.name < $1.name }
    }

    /// Normalize topic name to ID format (lowercase, dashes).
    private func normalizeForID(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "-")
    }
}
