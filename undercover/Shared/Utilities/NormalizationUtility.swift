
//
//  NormalizationUtility.swift
//  undercoverApp
//
//  Single source of truth for normalization and concept extraction.
//  This replaces duplicated normalization logic and ensures consistent concept identity.
//

import Foundation

/// Global normalization utility used for concept identity in the word-generation system.
public enum NormalizationUtility: Sendable {

    /// Normalize a concept for comparison and storage.
    ///
    /// - Lowercase
    /// - Remove leading/trailing whitespace
    /// - Remove diacritics (é → e, ñ → n, etc.)
    /// - Remove punctuation and symbols
    /// - Collapse multiple spaces to a single space
    ///
    /// Examples:
    /// - "Nike's" → "nikes"
    /// - "Café" → "cafe"
    /// - "New   York" → "new york"
    /// - "McDonald's" → "mcdonalds"
    public static nonisolated func normalize(_ value: String?) -> String {
        guard let value else {
            return ""
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let lowercased = trimmed.lowercased()

        let folded = lowercased.folding(
            options: .diacriticInsensitive,
            locale: .current
        )

        let noPunctuation = folded.components(
            separatedBy: CharacterSet.punctuationCharacters
                .union(.symbols)
        ).joined()

        let components = noPunctuation.components(
            separatedBy: .whitespaces
        )

        return components
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Create a canonical pair key for uniqueness.
    ///
    /// Returns the same key regardless of which concept
    /// is civilian or undercover.
    ///
    /// Examples:
    /// - pairKey("Nike", "Adidas") → "adidas|nike"
    /// - pairKey("Adidas", "Nike") → "adidas|nike"
    public static nonisolated func pairKey(
        _ civilian: String,
        _ undercover: String
    ) -> String {
        let c1 = normalize(civilian)
        let c2 = normalize(undercover)

        let (first, second) = c1 < c2
            ? (c1, c2)
            : (c2, c1)

        return "\(first)|\(second)"
    }

    /// Extract individual normalized concepts from a pair.
    ///
    /// Empty concepts are ignored.
    public static nonisolated func conceptsFromPair(
        civilian: String,
        undercover: String
    ) -> Set<String> {
        Set(
            [civilian, undercover]
                .map(normalize)
                .filter { !$0.isEmpty }
        )
    }

    /// Extract the first non-empty localized value from a dictionary.
    ///
    /// The dictionary order is used when no preferred language
    /// is specified.
    public static nonisolated func firstNonEmpty(
        from values: [String: String]
    ) -> String {
        values.first(where: { !$0.value.isEmpty })?.value ?? ""
    }

    /// Extract the first non-empty localized value using
    /// a preferred language order, then fall back to any value.
    public static nonisolated func firstNonEmpty(
        in values: [String: String],
        preferredLanguages: [String]
    ) -> String {
        for language in preferredLanguages {
            if let value = values[language], !value.isEmpty {
                return value
            }
        }

        return firstNonEmpty(from: values)
    }
}

// MARK: - Extension for consistency with existing code

extension String {

    /// Convenience method to normalize a string.
    public var normalized: String {
        NormalizationUtility.normalize(self)
    }
}
