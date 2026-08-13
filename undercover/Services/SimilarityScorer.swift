//
//  SimilarityScorer.swift
//  undercoverApp
//
//  Hybrid scorer: offline Jaro-Winkler + phonetic base,
//  optionally enriched with a semantic score from an AI provider.
//
//  IMPORTANT: SemanticSimilarityProvider is intentionally NOT called
//  inside generator loops. It is only used for post-hoc scoring in
//  BatchPairGenerator and offline analysis tools — never in the live game path.
//

import Foundation

// MARK: - Semantic provider

public protocol SemanticSimilarityProvider: Sendable {
    /// Cosine-style similarity in [0, 1], or nil on failure.
    func similarity(between a: String, and b: String) async -> Double?
}

/// Asks Claude Haiku to rate similarity. Use sparingly — not in loops.
public final class AnthropicSemanticProvider: SemanticSimilarityProvider {

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    public init() {}

    public func similarity(between a: String, and b: String) async -> Double? {
        guard Config.anthropicAPIKey.hasPrefix("sk-ant-"),
              Config.anthropicAPIKey != "sk-ant-REPLACE_ME" else { return nil }

        let prompt = """
        Rate the semantic similarity between these two words from 0.0 (unrelated) to 1.0 (identical).
        Respond with ONLY a decimal number.

        Word 1: \(a)
        Word 2: \(b)
        """

        let body: [String: Any] = [
            "model":      "claude-haiku-4-5-20251001",
            "max_tokens": 10,
            "messages":   [["role": "user", "content": prompt]]
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 6

        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }

        struct Envelope: Decodable {
            struct Block: Decodable { let type: String; let text: String? }
            let content: [Block]
        }
        guard
            let env  = try? JSONDecoder().decode(Envelope.self, from: data),
            let text = env.content.first(where: { $0.type == "text" })?.text,
            let val  = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)),
            (0.0...1.0).contains(val)
        else { return nil }

        return val
    }
}

// MARK: - Score

public struct SimilarityScore: Sendable {
    public let semantic:  Double    // 0 when provider unavailable
    public let lexical:   Double
    public let phonetic:  Double
    public let penalties: Double

    /// Full hybrid total: 60% semantic + 25% lexical + 15% phonetic − penalties.
    public var total: Double {
        max(0, min(1, 0.60 * semantic + 0.25 * lexical + 0.15 * phonetic - penalties))
    }

    /// Offline total (no semantic component): renormalised to lexical + phonetic only.
    public var offlineTotal: Double {
        max(0, min(1, 0.625 * lexical + 0.375 * phonetic - penalties))
    }
}

// MARK: - Scorer

public struct SimilarityScorer: Sendable {

    public init() {}

    // MARK: Jaro-Winkler

    public func jaroWinkler(_ s1: String, _ s2: String) -> Double {
        let a = Array(s1), b = Array(s2)
        let l1 = a.count, l2 = b.count
        if l1 == 0 && l2 == 0 { return 1.0 }
        if l1 == 0 || l2 == 0 { return 0.0 }

        let matchDist = max(l1, l2) / 2 - 1
        var aM = [Bool](repeating: false, count: l1)
        var bM = [Bool](repeating: false, count: l2)
        var matches = 0

        for i in 0..<l1 {
            let lo = max(0, i - matchDist)
            let hi = min(l2 - 1, i + matchDist)
            for j in lo...hi {
                if bM[j] || a[i] != b[j] { continue }
                aM[i] = true; bM[j] = true; matches += 1; break
            }
        }
        guard matches > 0 else { return 0.0 }

        var k = 0, transpositions = 0
        for i in 0..<l1 {
            guard aM[i] else { continue }
            while !bM[k] { k += 1 }
            if a[i] != b[k] { transpositions += 1 }
            k += 1
        }
        let m = Double(matches)
        let jaro = ((m/Double(l1)) + (m/Double(l2)) + ((m - Double(transpositions)/2)/m)) / 3.0

        var prefix = 0
        for i in 0..<min(4, min(l1, l2)) {
            if a[i] == b[i] { prefix += 1 } else { break }
        }
        return jaro + Double(prefix) * 0.1 * (1.0 - jaro)
    }

    // MARK: Phonetic (simplified metaphone)

    public func phoneticSimilarity(_ a: String, _ b: String) -> Double {
        let kA = metaphoneKey(a), kB = metaphoneKey(b)
        if kA.isEmpty && kB.isEmpty { return 1.0 }
        if kA == kB { return 1.0 }
        let maxLen = max(kA.count, kB.count)
        guard maxLen > 0 else { return 0.0 }
        let arrA = Array(kA), arrB = Array(kB)
        var prefix = 0
        for i in 0..<min(kA.count, kB.count) {
            if arrA[i] == arrB[i] { prefix += 1 } else { break }
        }
        return Double(prefix) / Double(maxLen)
    }

    private func metaphoneKey(_ s: String) -> String {
        let vowels: Set<Character> = ["A","E","I","O","U"]
        var result = ""
        let chars  = Array(s.uppercased())
        guard let first = chars.first else { return "" }
        result.append(first)
        var last: Character? = first
        for c in chars.dropFirst() {
            var m = c
            switch c {
            case "B","F","P","V":                     m = "F"
            case "C","G","J","K","Q","S","X","Z":     m = "S"
            case "D","T":                             m = "T"
            case "M","N":                             m = "N"
            default:                                  m = c
            }
            if vowels.contains(m) { continue }
            if m != last { result.append(m); last = m }
        }
        return result
    }

    // MARK: Playability

    public func arePluralForms(_ a: String, _ b: String) -> Bool {
        func singular(_ w: String) -> String {
            let l = w.lowercased()
            if l.hasSuffix("es") && l.count > 2 { return String(l.dropLast(2)) }
            if l.hasSuffix("s")  && l.count > 1 { return String(l.dropLast()) }
            return l
        }
        return singular(a) == singular(b) && a.lowercased() != b.lowercased()
    }

    public func isPlayable(_ a: String, _ b: String) -> Bool {
        a.count >= 3 && b.count >= 3
            && a.lowercased() != b.lowercased()
            && !arePluralForms(a, b)
    }

    // MARK: Combined score

    public func combinedScore(a: String, b: String, semantic: Double?) -> SimilarityScore {
        let lexical  = jaroWinkler(a, b)
        let phonetic = phoneticSimilarity(a, b)
        let sem      = semantic ?? 0.0
        let lA = a.lowercased(), lB = b.lowercased()

        var penalty = 0.0
        if arePluralForms(lA, lB) {
            penalty = 0.2
        } else if lA != lB && a.count >= 4 && b.count >= 4 && editDistance(lA, lB) <= 1 {
            penalty = 0.2
        }
        return SimilarityScore(semantic: sem, lexical: lexical, phonetic: phonetic, penalties: penalty)
    }

    // MARK: Levenshtein

    public func editDistance(_ a: String, _ b: String) -> Int {
        let s = Array(a), t = Array(b)
        let m = s.count, n = t.count
        if m == 0 { return n }; if n == 0 { return m }
        var dist = (0...m).map { row -> [Int] in
            var r = [Int](repeating: 0, count: n + 1)
            r[0] = row; return r
        }
        for j in 0...n { dist[0][j] = j }
        for i in 1...m {
            for j in 1...n {
                dist[i][j] = s[i-1] == t[j-1]
                    ? dist[i-1][j-1]
                    : min(dist[i-1][j], dist[i][j-1], dist[i-1][j-1]) + 1
            }
        }
        return dist[m][n]
    }
}
