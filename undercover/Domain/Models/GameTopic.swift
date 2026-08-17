//
//  GameTopic.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation

public struct GameTopic: Identifiable, Hashable, Sendable {

    public let id: String
    public let name: String
    public let source: Source

    public enum Source: Sendable {
        case local
        case ai
    }

    public init(
        id: String,
        name: String,
        source: Source
    ) {
        self.id = id
        self.name = name
        self.source = source
    }
}
