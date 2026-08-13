//
//  Player.swift
//  undercoverApp
//

import Foundation

public struct Player: Identifiable, Hashable, Sendable {
    public let id:   UUID
    public let name: String
    public var isEliminated: Bool

    public init(id: UUID = UUID(), name: String, isEliminated: Bool = false) {
        self.id          = id
        self.name        = name
        self.isEliminated = isEliminated
    }
}
