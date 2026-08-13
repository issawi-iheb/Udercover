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

    /// Decodes from a flat { "en": "cat", "fr": "chat", … } JSON object.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.values = try container.decode([String: String].self)
    }

    /// Encodes back to the same flat { "en": "cat", … } format.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    /// Returns the word for the given language.
    /// Lookup order: requested language → English → any non-empty value → "".
    /// Uses `language.rawValue` which matches the JSON keys exactly ("en", "fr", "ar", "es", "tn").
    public func localized(for language: AppLanguage) -> String {
        if let v = values[language.rawValue], !v.isEmpty { return v }
        if let en = values[AppLanguage.english.rawValue], !en.isEmpty { return en }
        return values.values.first(where: { !$0.isEmpty }) ?? ""
    }

    public var allValues: [String] { values.values.filter { !$0.isEmpty } }
}

// MARK: - WordPair

public struct WordPair: Codable, Identifiable, Sendable {

    public var id: String {
        "\(civilian.values["en"] ?? "")|\(undercover.values["en"] ?? "")"
    }

    public let civilian:   LocalizedWord
    public let undercover: LocalizedWord
    public let topic:      String
    public let similarity: Double?

    private static let classifier = PairDifficultyClassifier()

    public var difficulty: PairDifficulty {
        Self.classifier.classify(score: similarity ?? 0.62)
    }

    /// Stable lowercase English civilian word used to track played pairs.
    public var trackingKey: String {
        (civilian.values[AppLanguage.english.rawValue] ?? civilian.values.values.first ?? "")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
