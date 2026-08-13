//
//  GameAssignment.swift
//  undercoverApp
//

import Foundation

public struct GameAssignment: Sendable {
    public let wordsByPlayer:       [UUID: String]
    public let rolesByPlayer:       [UUID: PlayerRole]
    public let civilianWord:        String
    public let undercoverWord:      String
    public let undercoverPlayerID:  UUID
    public let mrWhitePlayerID:     UUID?   // nil when Mr. White mode is off
}
