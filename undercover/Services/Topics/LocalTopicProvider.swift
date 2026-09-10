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
    func topics() async -> [String]
}

// MARK: - Local Provider

/// Provides topics from the local words.json repository.
public actor LocalTopicProvider: TopicProvider {

    private let repository = WordRepository()

    public func topics() async -> [String] {
        repository.topics
    }
}
