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

    public func topics() async -> [GameTopic] {
        if !cachedTopics.isEmpty {
            return cachedTopics
        }

        let allTopics = await withTaskGroup(
            of: [GameTopic].self
        ) { group in

            for provider in providers {
                group.addTask {
                    await provider.topics()
                }
            }

            var result: [GameTopic] = []

            for await topics in group {
                result.append(contentsOf: topics)
            }

            return result
        }

        cachedTopics = mergeTopics(allTopics)

        print("""
        📚 [TopicService] Loaded \(cachedTopics.count) topics
        📦 Local: \(cachedTopics.filter { $0.source == .local }.count)
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
            $0.name < $1.name
        }
    }
}
