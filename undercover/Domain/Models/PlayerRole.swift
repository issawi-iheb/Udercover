//
//  PlayerRole.swift
//  undercoverApp
//

import Foundation

public enum PlayerRole: Equatable, Hashable, Sendable, CaseIterable {
    case civilian
    case undercover
    case mrWhite    // Receives a blank word; wins by guessing the civilian word after elimination.

    public var displayName: String {
        switch self {
        case .civilian:   return "Civilian"
        case .undercover: return "Undercover"
        case .mrWhite:    return "Mr. White"
        }
    }

    /// True for roles that are adversarial to civilians.
    public var isOpponent: Bool { self == .undercover || self == .mrWhite }
}
