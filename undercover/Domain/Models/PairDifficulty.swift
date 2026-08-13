//
//  PairDifficulty.swift
//  undercoverApp
//

import Foundation

public enum PairDifficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard

    public var label: String { rawValue.capitalized }

    /// Similarity score range that maps to this difficulty band.
    public var scoreRange: ClosedRange<Double> {
        switch self {
        case .easy:   return 0.40...0.54
        case .medium: return 0.55...0.69
        case .hard:   return 0.70...1.00
        }
    }
}

public struct PairDifficultyClassifier: Sendable {
    public init() {}

    public func classify(score: Double) -> PairDifficulty {
        switch score {
        case ..<0.55:     return .easy
        case 0.55..<0.70: return .medium
        default:           return .hard
        }
    }
}
