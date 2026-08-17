//
//  TopicService.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation

public actor TopicService {

    private let repository: WordRepository
    private let aiProvider: FoundationModelsTopicProvider

    private var cachedTopics: [GameTopic] = []


    public init(
        repository: WordRepository = WordRepository(),
        aiProvider: FoundationModelsTopicProvider = FoundationModelsTopicProvider()
    ) {
        self.repository = repository
        self.aiProvider = aiProvider
    }


    // MARK: - Public

    public func topics() async -> [GameTopic] {

        if !cachedTopics.isEmpty {
            return cachedTopics
        }


        // Local topics
        let localTopics = repository.topics.map {
            GameTopic(
                id: normalize($0),
                name: $0.capitalized, source: .local
            )
        }


        // AI topics
        let aiTopics = await aiProvider.topics()

        let generatedTopics = aiTopics.map {
            GameTopic(
                id: normalize($0),
                name: $0.capitalized, source: .ai
            )
        }


        // Merge
        let result = merge(
            localTopics,
            generatedTopics
        )


        cachedTopics = result

        return result
    }


    // MARK: - Merge

    private func merge(
        _ first: [GameTopic],
        _ second: [GameTopic]
    ) -> [GameTopic] {

        var result: [GameTopic] = []
        var seen = Set<String>()


        for topic in first + second {

            let key = normalize(topic.id)

            guard !seen.contains(key) else {
                continue
            }

            seen.insert(key)
            result.append(topic)
        }


        return result.sorted {
            $0.name < $1.name
        }
    }


    // MARK: - Normalization

    private func normalize(_ value: String) -> String {

        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(
                options: .diacriticInsensitive,
                locale: .current
            )
            .replacingOccurrences(
                of: " ",
                with: "-"
            )
    }
}
