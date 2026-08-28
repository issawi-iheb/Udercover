//  NormalizationUtility.swift
//  undercoverApp
//
//  Single source of truth for normalization and concept extraction.
//  This replaces duplicated normalization logic and ensures consistent concept identity.

import Foundation

/// Global normalization utility used for concept identity in the word-generation system.
public enum NormalizationUtility: Sendable {

    /// Normalize a concept for comparison and storage.
    ///
    /// - Lowercase
    /// - Remove leading/trailing whitespace
    /// - Remove diacritics (é → e, ñ → n, etc.)
    /// - Remove punctuation, symbols, extra whitespace
    /// - Collapse multiple spaces to single space
    ///
    /// Examples:
    /// - "Nike's" → "nike s" (apostrophe removed)
    /// - "Café" → "cafe" (accent removed)
    /// - "New  York" → "new york" (multiple spaces collapsed)
    /// - "McDonald's" → "mcdonald s" (apostrophe removed)
    public static nonisolated func normalize(_ value: String?) -> String {
        guard let value = value else { return "" }

        return value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .split { $0.isWhitespace || $0.isPunctuation || $0.isSymbol }
            .joined(separator: " ")
    }

    /// Create a canonical pair key for uniqueness.
    ///
    /// Returns a key that represents the pair regardless of which concept
    /// is civilian vs. undercover.
    ///
    /// Uses min/max ordering to ensure (A,B) and (B,A) produce the same key.
    ///
    /// Example:
    /// - pairKey("Nike", "Adidas") → "adidas|nike" (alphabetical order)
    /// - pairKey("Adidas", "Nike") → "adidas|nike" (same key)
    public static nonisolated func pairKey(_ civilian: String, _ undercover: String) -> String {
        let c1 = normalize(civilian)
        let c2 = normalize(undercover)

        let (first, second) = (c1 < c2) ? (c1, c2) : (c2, c1)
        return "\(first)|\(second)"
    }

    /// Extract individual normalized concepts from a pair.
    ///
    /// Returns a set of both civilian and undercover words,
    /// normalized for comparison against exclusion lists.
    public static nonisolated func conceptsFromPair(civilian: String, undercover: String) -> Set<String> {
        Set([
            normalize(civilian),
            normalize(undercover)
        ])
    }

    /// Extract the first non-empty localized value from a dictionary, falling back to empty string.
    ///
    /// This provides deterministic, language-independent concept extraction.
    /// The order of checking is: requested language (if provided), then English, then any other non-empty.
    /// If no non-empty value exists, returns empty string.
    ///
    /// - Note: For concept identity, we use the first non-empty value regardless of language.
    ///   The caller can specify a preferred language order if desired, but for uniqueness we want
    ///   any non-empty value to represent the concept.
    public static nonisolated func firstNonEmpty(from values: [String: String]) -> String {
        // First, try to find any non-empty value (language-independent)
        if let value = values.first(where: { !$0.value.isEmpty })?.value {
            return value
        }
        return ""
    }

    /// Override to specify a preferred language order for extraction (e.g., for UI display).
    /// For uniqueness, we use the language-independent `firstNonEmpty(from:)` above.
    public static nonisolated func firstNonEmpty(in values: [String: String], preferredLanguages: [String]) -> String {
        for lang in preferredLanguages {
            if let value = values[lang], !value.isEmpty {
                return value
            }
        }
        return firstNonEmpty(from: values)
    }
}

// MARK: - Extension for consistency with existing code

extension String {
    /// Convenience method to normalize a string
    public var normalized: String {
        NormalizationUtility.normalize(self)
    }
}