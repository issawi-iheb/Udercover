//
//  BatchPairGenerator.swift
//  undercoverApp
//
//  Offline dev tool for pre-populating words.json.
//  NOT used at runtime — exclude from the app target, include in a CLI or test target.
//

import Foundation

public final class BatchPairGenerator {

    private let scorer = SimilarityScorer()
    public init() {}

    public func generatePairs(
        topic:       String,
        words:       [String],
        maxNeighbors: Int = 50,
        targetCount:  Int = 1000,
        scoreRange:   ClosedRange<Double> = 0.55...0.80
    ) -> [WordPair] {

        let normalized = Array(Set(
            words.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        ))

        // Build neighbour map sorted by Jaro-Winkler descending.
        var lexicalScores: [String: [(String, Double)]] = [:]
        for word in normalized {
            var neighbours = normalized.compactMap { candidate -> (String, Double)? in
                guard candidate != word else { return nil }
                return (candidate, scorer.jaroWinkler(word, candidate))
            }
            neighbours.sort { $0.1 > $1.1 }
            lexicalScores[word] = Array(neighbours.prefix(maxNeighbors))
        }

        var results: [WordPair] = []
        var seen = Set<String>()

        outer: for word in normalized {
            guard let neighbours = lexicalScores[word] else { continue }
            for (neighbour, score) in neighbours {
                guard scoreRange.contains(score), scorer.isPlayable(word, neighbour) else { continue }

                // Deterministic civilian/undercover assignment.
                let civilian:   String
                let undercover: String
                if word.count != neighbour.count {
                    civilian   = word.count < neighbour.count ? word : neighbour
                    undercover = word.count < neighbour.count ? neighbour : word
                } else {
                    civilian   = word < neighbour ? word : neighbour
                    undercover = word < neighbour ? neighbour : word
                }

                let key = "\(civilian)|\(undercover)|\(topic)"
                guard !seen.contains(key) else { continue }
                seen.insert(key)

                results.append(WordPair(
                    civilian:   LocalizedWord(values: allLangs(civilian)),
                    undercover: LocalizedWord(values: allLangs(undercover)),
                    topic:      topic,
                    similarity: score       // actual computed score, not hardcoded
                ))
                if results.count >= targetCount { break outer }
            }
        }
        return results
    }

    private func allLangs(_ word: String) -> [String: String] {
        ["en": word, "ar": word, "fr": word, "es": word, "tn": word]
    }
}
