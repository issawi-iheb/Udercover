//
//  WordGeneratorProtocol.swift
//  undercoverApp
//

import Foundation

// MARK: - Protocol

/// All generators conform to this. Each is an `actor` to safely own its cache.
public protocol WordGeneratorProtocol: Actor {
    var generatorName: String { get }
    var isAvailable:   Bool   { get }

    func randomPair(
        topic:           String,
        language:        AppLanguage,
        difficulty:      PairDifficulty,
        excluding used:  Set<String>
    ) async throws -> WordPair
}

// MARK: - Errors

public enum WordGeneratorError: LocalizedError, Sendable {
    case unavailable(String)
    case networkError(Error)
    case invalidResponse
    case parsingFailed(String)
    case noPairsAvailable

    public var errorDescription: String? {
        switch self {
        case .unavailable(let r):  return "Generator unavailable: \(r)"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .invalidResponse:     return "Invalid response from server."
        case .parsingFailed(let s):return "Parsing failed: \(s)"
        case .noPairsAvailable:    return "No word pairs available for the selected filters."
        }
    }
}
