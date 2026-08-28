//
//  BatchPairGenerator.swift
//  undercoverApp
//

import Foundation

/// Generates word pairs for offline word repository.
///
/// This is a development tool, not used at runtime.
/// It uses Jaro-Winkler similarity to pair concepts lexically.
public final class BatchPairGenerator {

    private let scorer = SimilarityScorer()

    public init() {}

    /// Generate word pairs for a topic using lexical similarity.
    ///
    /// - Parameters:
    ///   - topic: The topic/category for pairs
    ///   - words: List of candidate words/concepts
    ///   - maxNeighbors: How many similar neighbors to consider per word (default: 50)
    ///   - targetCount: Target number of pairs to generate (default: 1000)
    ///   - scoreRange: Acceptable similarity range (default: 0.55...0.80)
    ///
    /// - Returns: Array of generated WordPair objects
    public func generatePairs(
        topic: String,
        words: [String],
        maxNeighbors: Int = 50,
        targetCount: Int = 1000,
        scoreRange: ClosedRange<Double> = 0.55...0.80
    ) -> [WordPair] {

        // Normalize and deduplicate input words
        let normalized = Array(Set(
            words.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        ))

        print("""
        🔧 [BatchPairGenerator] Starting
        Topic: \(topic)
        Input words: \(normalized.count)
        Target pairs: \(targetCount)
        Similarity range: \(scoreRange.lowerBound)–\(scoreRange.upperBound)
        """)

        // Build similarity map for each word
        var similarityMap: [String: [(String, Double)]] = [:]

        for word in normalized {
            var neighbors = normalized.compactMap { candidate -> (String, Double)? in
                guard candidate != word else { return nil }
                return (candidate, scorer.jaroWinkler(word, candidate))
            }

            // Sort by similarity descending
            neighbors.sort { $0.1 > $1.1 }
            similarityMap[word] = Array(neighbors.prefix(maxNeighbors))
        }

        // Generate pairs
        var results: [WordPair] = []
        var seenKeys = Set<String>()

        outer: for word in normalized {
            guard let neighbors = similarityMap[word] else { continue }

            for (neighbor, score) in neighbors {

                // Must be in acceptable range
                guard scoreRange.contains(score) else { continue }

                // Must pass playability check
                guard scorer.isPlayable(word, neighbor) else { continue }

                let civilian = word
                let undercover = neighbor

                // Dedup check
                let key = "\(NormalizationUtility.pairKey(civilian, undercover))|\(NormalizationUtility.normalize(topic))"
                guard !seenKeys.contains(key) else { continue }

                seenKeys.insert(key)

                results.append(WordPair(
                    civilian: LocalizedWord(values: multiLang(civilian)),
                    undercover: LocalizedWord(values: multiLang(undercover)),
                    topic: topic,
                    similarity: score
                ))

                if results.count >= targetCount { break outer }
            }
        }

        print("""
        ✅ [BatchPairGenerator] Generated \(results.count) pairs
        """)

        return results
    }

    // MARK: - Private

    /// Create multilingual word entry (same word in all languages).
    private func multiLang(_ word: String) -> [String: String] {
        [
            "en": word,
            "fr": word,
            "es": word,
            "ar": word,
            "tn": word
        ]
    }
}
