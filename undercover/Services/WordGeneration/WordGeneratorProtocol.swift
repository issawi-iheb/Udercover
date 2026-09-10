//
//  WordGeneratorProtocol.swift
//  undercoverApp
//
//  Protocol for word-pair generators.
//  All generators are actors for thread-safe cache management.
//

import Foundation

public enum WordGeneratorKind: Sendable, nonisolated Equatable {
    case local
    case background
}
/// Protocol that all word-pair generators must conform to.
///
/// Implementations are actors to safely manage their own caches.
/// Generators are called in priority order by WordGeneratorService.
///
/// - Local: Fast, deterministic, limited vocabulary
/// - LLM: Slow, creative, unlimited vocabulary
public protocol WordGeneratorProtocol: Actor {

    /// Human-readable name of this generator (for logging)
    var generatorName: String { get }
    nonisolated var kind: WordGeneratorKind { get }

    /// Whether this generator is available on this device/configuration
    var isAvailable: Bool { get }

    /// Generate a random word pair for the given parameters.
    ///
    /// - Parameters:
    ///   - topic: The topic/category for the pair
    ///   - language: The language for localized concepts
    ///   - difficulty: Desired difficulty level (easy/medium/hard)
    ///   - excluding: Set of concepts that have already been used (must be normalized)
    ///
    /// - Returns: A new WordPair matching the criteria
    /// - Throws: WordGeneratorError if no suitable pair can be generated
    func randomPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair
}

/// Errors that can occur during word generation.
public enum WordGeneratorError: LocalizedError, Sendable, Equatable {
    case unavailable(String)
    case networkError(String)
    case invalidResponse
    case parsingFailed(String)
    case noPairsAvailable

    public var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            return "Generator unavailable: \(reason)"

        case .networkError(let message):
            return "Network error: \(message)"

        case .invalidResponse:
            return "Invalid response from generator"
        case .parsingFailed(let detail):
            return "Parsing failed: \(detail)"
        case .noPairsAvailable:
            return "No word pairs available for the given filters"
        }
    }
}
