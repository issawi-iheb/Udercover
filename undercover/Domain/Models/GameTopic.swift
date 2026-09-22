//
//  GameTopic.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation

// MARK: - Models

/// Represents a game topic.
public struct GameTopic: Hashable, Identifiable {
    public let id: String       // Normalized identifier
    public let name: String     // Display name
    public nonisolated let source: TopicSource

    public nonisolated init(id: String, name: String, source: TopicSource) {
        self.id = id
        self.name = name
        self.source = source
    }
}

/// Source of a topic.
public enum TopicSource: String, Hashable {
    case local
    case ai
}
