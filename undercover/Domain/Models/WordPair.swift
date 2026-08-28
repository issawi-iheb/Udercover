//
//  WordPair.swift
//  undercoverApp
//

import Foundation

// MARK: - LocalizedWord

public struct LocalizedWord: Codable, Hashable, Sendable {

    public let values: [String: String]

    public init(values: [String: String]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.values = try container.decode([String: String].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    public func localized(for language: AppLanguage) -> String {

        if let value = values[language.rawValue],
           !value.isEmpty {
            return value
        }

        if let english = values[AppLanguage.english.rawValue],
           !english.isEmpty {
            return english
        }

        return values.values.first {
            !$0.isEmpty
        } ?? ""
    }

    public var allValues: [String] {
        values.values.filter {
            !$0.isEmpty
        }
    }

    /// Deterministic concept representation.
    ///
    /// The actual language does not matter here.
    /// We only need one stable value to identify the concept.
    public var firstNonEmpty: String {
        values
            .sorted(by: { $0.key < $1.key })
            .compactMap { $0.value.isEmpty ? nil : $0.value }
            .first ?? ""
    }
}

// MARK: - WordPair

public struct WordPair: Codable, Identifiable, Sendable {

    public var id: String {

        let civilianConcept = civilian.firstNonEmpty
        let undercoverConcept = undercover.firstNonEmpty

        let first: String
        let second: String

        if civilianConcept < undercoverConcept {
            first = civilianConcept
            second = undercoverConcept
        } else {
            first = undercoverConcept
            second = civilianConcept
        }

        return "\(first)|\(second)"
    }

    public let civilian: LocalizedWord
    public let undercover: LocalizedWord
    public let topic: String
    public let similarity: Double?

    private static let classifier = PairDifficultyClassifier()

    public var difficulty: PairDifficulty {
        Self.classifier.classify(
            score: similarity ?? 0.62
        )
    }

    /// All concepts represented by this pair.
    ///
    /// Both civilian and undercover concepts are included.
    public var concepts: Set<String> {

        NormalizationUtility.conceptsFromPair(
            civilian: civilian.firstNonEmpty,
            undercover: undercover.firstNonEmpty
        )
    }
}
