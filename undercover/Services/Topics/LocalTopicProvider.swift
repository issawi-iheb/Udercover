//
//  TopicProvider.swift & TopicService.swift
//  undercover
//
//  Provides topics from local repository and/or AI.
//

import Foundation

// MARK: - Protocol

/// Provides a list of topics/categories for the game.
public protocol TopicProvider: Sendable {
    nonisolated var  source: TopicSource { get }
    func topics() async -> [GameTopic]
}

// MARK: - Local Provider

/// Provides topics from the local words.json repository.

public actor LocalTopicProvider: TopicProvider {
    public nonisolated let source: TopicSource = .local

    private let repository: any TopicRepository

    public init(
        repository: any TopicRepository
    ) {
        self.repository = repository
    }

    public func topics() async -> [GameTopic] {
        repository.topics.compactMap { topic in
            let name = topic.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !name.isEmpty else {
                return nil
            }

            return GameTopic(
                id: normalizeForID(name),
                name: name.capitalized,
                source: .local
            )
        }
    }

    private nonisolated func normalizeForID(
        _ value: String
    ) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(
                options: .diacriticInsensitive,
                locale: .current
            )
            .replacingOccurrences(of: " ", with: "-")
    }
}

public extension LocalTopicProvider {

    init() {
        self.init(
            repository: WordRepository()
        )
    }
}
