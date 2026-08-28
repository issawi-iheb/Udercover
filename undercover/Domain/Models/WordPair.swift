//  WordPair.swift
//  undercoverApp
//
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
        if let value = values[language.rawValue], !value.isEmpty {
            return value
        }

        if let english = values[AppLanguage.english.rawValue],
           !english.isEmpty {
            return english
        }

        return values.values.first(where: { !$0.isEmpty }) ?? ""
    }

    public var allValues: [String] {
        values.values.filter { !$0.isEmpty }
    }

    /// Extract the first non-empty localized value for concept identity.
    /// This is language-independent and deterministic.
    public var firstNonEmpty: String {
        // First, try to find any non-empty value (language-independent)
        if let value = values.first(where: { !$0.value.isEmpty })?.value {
            return value
        }
        return ""
    }
}

// MARK: - WordPair

public struct WordPair: Codable, Identifiable, Sendable {

    public var id: String {
        // Use deterministic pair key for ID
        let civilianConcept = civilian.firstNonEmpty
        let undercoverConcept = undercover.firstNonEmpty
        // Canonical pair key: min|max for consistent ordering
        let (first, second) = (civilianConcept < undercoverConcept) ? (civilianConcept, undercoverConcept) : (undercoverConcept, civilianConcept)
        return "\(first)|\(second)"
    }

    public let civilian:   LocalizedWord
    public let undercover: LocalizedWord
    public let topic:      String
    public let similarity: Double?

    private static let classifier = PairDifficultyClassifier()

    public var difficulty: PairDifficulty {
        Self.classifier.classify(score: similarity ?? 0.62)
    }

    /// Get the set of normalized concepts contained in this pair.
    /// This contains BOTH civilian and undercover concepts.
    public var concepts: Set<String> {
        NormalizationUtility.conceptsFromPair(
            civilian: civilian.firstNonEmpty,
            undercover: undercover.firstNonEmpty
        )
    }
}
