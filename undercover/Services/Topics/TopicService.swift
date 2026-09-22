//
//  TopicService.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation

public protocol TopicRepository: Sendable {
    nonisolated var topics: [String] { get }
}

public actor TopicService {

    private let providers: [any TopicProvider]
    private var cachedTopics: [GameTopic] = []

    public init(
        providers: [any TopicProvider]
    ) {
        self.providers = providers
    }

    public func localTopics() async -> [GameTopic] {
        if !cachedTopics.isEmpty {
            return cachedTopics
        }

        guard let provider = providers.first(
            where: { $0.source == .local }
        ) else {
            return cachedTopics
        }

        let topics = await provider.topics()

        cachedTopics = mergeTopics(topics)
        print("""
        📚 [TopicService] Loaded \(cachedTopics.count) topics
        📦 Local: \(cachedTopics.filter { $0.source == .local }.count)
        """)
        return cachedTopics
    }

    public func loadAITopics() async -> [GameTopic] {
        guard let provider = providers.first(where: {
            $0.source == .ai
        }) else {
            return cachedTopics
        }

        let topics = await provider.topics()

        cachedTopics = mergeTopics(
            cachedTopics + topics
        )
        print("""
        🧠 AI: \(cachedTopics.filter { $0.source == .ai }.count)
        """)

        return cachedTopics
    }

    private func mergeTopics(
        _ topics: [GameTopic]
    ) -> [GameTopic] {
        var result: [GameTopic] = []
        var seen = Set<String>()

        for topic in topics {
            guard seen.insert(topic.id).inserted else {
                continue
            }

            result.append(topic)
        }

        return result.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }
    }
}
