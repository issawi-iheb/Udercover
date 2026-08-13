//
//  FoundationModelsWordGenerator.swift
//  undercoverApp
//
//  Uses Apple's on-device FoundationModels (iOS 26+, Apple Intelligence).
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public actor FoundationModelsWordGenerator: WordGeneratorProtocol {

    public let generatorName = "Apple Intelligence (On-Device)"

    public var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    private var cache: [String: [WordPair]] = [:]

    // MARK: - Protocol

    public func randomPair(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) async throws -> WordPair {
        guard isAvailable else {
            throw WordGeneratorError.unavailable("Apple Intelligence is not available on this device.")
        }

        let key        = "\(language.rawValue)|\(topic)|\(difficulty.rawValue)"
        let normalised = Set(excluding.map { $0.lowercased() })

        func filtered(_ pairs: [WordPair]) -> [WordPair] {
            pairs.filter { !normalised.contains($0.trackingKey) && $0.difficulty == difficulty }
        }

        var available = filtered(cache[key] ?? [])

        if available.isEmpty {
            let fresh = try await fetchViaLLM(topic: topic, language: language,
                                              difficulty: difficulty, excluding: excluding)
            cache[key, default: []].append(contentsOf: fresh)
            available = filtered(fresh)
        }

        guard let pair = available.randomElement() else {
            throw WordGeneratorError.noPairsAvailable
        }
        return pair
    }

    // MARK: - On-Device LLM

    private func fetchViaLLM(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) async throws -> [WordPair] {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else {
            throw WordGeneratorError.unavailable("Apple Intelligence requires iOS 26 or newer.")
        }

        let diffDesc: String
        switch difficulty {
        case .easy:   diffDesc = "very different, easy to distinguish (0.40–0.54)"
        case .medium: diffDesc = "related but noticeably different (0.55–0.69)"
        case .hard:   diffDesc = "very close, tricky to distinguish (0.70–1.00)"
        }

        let avoidClause = excluding.isEmpty ? "" :
            "\nAvoid these civilian words: \(excluding.sorted().joined(separator: ", "))."
        let topicLine = topic.isEmpty ? "Pick any common everyday topic." : "Topic: \(topic)"

        let instructions = """
        You generate word pairs for the party game Undercover. \
        Output ONLY valid JSON — no markdown, no explanation. \
        All 5 language translations required per word (keys: en, ar, fr, es, tn).
        Format: [{"civilian":{"en":"","ar":"","fr":"","es":"","tn":""},"undercover":{"en":"","ar":"","fr":"","es":"","tn":""},"similarity":0.65}]
        """

        let prompt = """
        Generate exactly 10 UNIQUE Undercover word pairs.

        \(topicLine)

        Language: \(language.promptLabel)
        Difficulty: \(diffDesc)

        Every pair must contain two genuinely different concepts.

        Do NOT generate:
        - synonyms
        - translations of the same word
        - singular/plural variations
        - adjective/noun variations of the same concept
        - extremely similar objects
        - one word that is simply a more specific version of the other

        For example, DO NOT use:
        car / automobile
        cat / kitten
        dog / puppy
        restaurant / restaurant
        phone / smartphone

        Prefer pairs such as:
        cat / tiger
        coffee / tea
        piano / guitar
        beach / swimming pool
        pizza / burger

        Make every pair different from the other nine pairs.
        \(avoidClause)
        """

        let session  = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return try Self.parseJSON(response.content, topic: topic)

        #else
        throw WordGeneratorError.unavailable("Apple Intelligence is not available on this platform.")
        #endif
    }

    private static func parseJSON(_ text: String, topic: String) throws -> [WordPair] {
        var clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = clean.firstIndex(of: "["), let e = clean.lastIndex(of: "]"), s < e {
            clean = String(clean[s...e])
        }
        guard let d = clean.data(using: .utf8) else {
            throw WordGeneratorError.parsingFailed(clean)
        }
        struct Raw: Decodable {
            let civilian:   [String: String]
            let undercover: [String: String]
            let similarity: Double?
        }
        let rawPairs = try JSONDecoder().decode([Raw].self, from: d)

        var seen = Set<String>()
        var pairs: [WordPair] = []

        for raw in rawPairs {
            let civilian = LocalizedWord(values: raw.civilian)
            let undercover = LocalizedWord(values: raw.undercover)

            let civilianEnglish = normalize(raw.civilian["en"])
            let undercoverEnglish = normalize(raw.undercover["en"])

            // Must have both words.
            guard !civilianEnglish.isEmpty,
                  !undercoverEnglish.isEmpty else {
                continue
            }

            // Civilian and undercover cannot be the same word.
            guard civilianEnglish != undercoverEnglish else {
                continue
            }

            // Don't allow the same word to appear in multiple pairs.
            guard !seen.contains(civilianEnglish),
                  !seen.contains(undercoverEnglish) else {
                continue
            }

            let pair = WordPair(
                civilian: civilian,
                undercover: undercover,
                topic: topic,
                similarity: raw.similarity
            )

            guard !seen.contains(pair.trackingKey) else {
                continue
            }

            seen.insert(civilianEnglish)
            seen.insert(undercoverEnglish)

            pairs.append(pair)
        }

        guard !pairs.isEmpty else {
            throw WordGeneratorError.noPairsAvailable
        }

        return pairs
    }
    private static func normalize(_ value: String?) -> String {
        guard let value else { return "" }

        return value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
    }
}
