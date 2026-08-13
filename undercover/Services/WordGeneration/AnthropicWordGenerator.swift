//
//  AnthropicWordGenerator.swift
//  undercoverApp
//

import Foundation

public actor AnthropicWordGenerator: WordGeneratorProtocol {

    public let generatorName = "Claude (Anthropic)"

    public var isAvailable: Bool {
        let key = Config.anthropicAPIKey
        return key.hasPrefix("sk-ant-") && key != "sk-ant-REPLACE_ME"
    }

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    /// Cache keyed by "language|topic|difficulty".
    private var cache: [String: [WordPair]] = [:]

    // MARK: - Protocol

    public func randomPair(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) async throws -> WordPair {
        guard isAvailable else {
            throw WordGeneratorError.unavailable("Anthropic API key not configured.")
        }

        let key        = cacheKey(language: language, topic: topic, difficulty: difficulty)
        let normalised = Set(excluding.map { $0.lowercased() })

        func filtered(_ pairs: [WordPair]) -> [WordPair] {
            pairs.filter { !normalised.contains($0.trackingKey) && $0.difficulty == difficulty }
        }

        var available = filtered(cache[key] ?? [])

        if available.isEmpty {
            let fresh = try await fetch(topic: topic, language: language,
                                        difficulty: difficulty, excluding: excluding)
            cache[key, default: []].append(contentsOf: fresh)
            available = filtered(fresh)
        }

        guard let pair = available.randomElement() else {
            throw WordGeneratorError.noPairsAvailable
        }
        return pair
    }

    // MARK: - Network

    private func fetch(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) async throws -> [WordPair] {

        let diffDesc: String
        switch difficulty {
        case .easy:   diffDesc = "very different, easy to distinguish (similarity 0.40–0.54)"
        case .medium: diffDesc = "related but noticeably different (similarity 0.55–0.69)"
        case .hard:   diffDesc = "very close, tricky to distinguish (similarity 0.70–0.85)"
        }

        let avoidClause = excluding.isEmpty ? "" :
            "\nAvoid these civilian words: \(excluding.sorted().joined(separator: ", "))."
        let topicLine = topic.isEmpty ? "any common everyday topic (you choose)" : "Topic: \(topic)"

        let prompt = """
        Generate 15 word pairs for the party game "Undercover".

        \(topicLine)
        Language: \(language.promptLabel)
        Difficulty: \(diffDesc)\(avoidClause)

        Rules:
        - Each pair: one CIVILIAN word, one UNDERCOVER word.
        - Both words must be in \(language.promptLabel).
        - Semantically related but clearly distinct.
        - Match the requested difficulty level.
        - Include ALL 5 language translations per word (en, ar, fr, es, tn).
        - Return ONLY raw JSON — no markdown, no explanation.

        Format:
        [
          {
            "civilian":   {"en":"…","ar":"…","fr":"…","es":"…","tn":"…"},
            "undercover": {"en":"…","ar":"…","fr":"…","es":"…","tn":"…"},
            "similarity": 0.65
          }
        ]
        """

        let body: [String: Any] = [
            "model":      "claude-sonnet-4-6",
            "max_tokens": 2048,
            "messages":   [["role": "user", "content": prompt]]
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw WordGeneratorError.invalidResponse
        }

        return try decode(data, topic: topic)
    }

    // MARK: - Decoding

    private func decode(_ data: Data, topic: String) throws -> [WordPair] {
        struct Envelope: Decodable {
            struct Block: Decodable { let type: String; let text: String? }
            let content: [Block]
        }
        let env = try JSONDecoder().decode(Envelope.self, from: data)
        guard let text = env.content.first(where: { $0.type == "text" })?.text else {
            throw WordGeneratorError.invalidResponse
        }
        return try parseJSON(text, topic: topic)
    }

    private func parseJSON(_ text: String, topic: String) throws -> [WordPair] {
        let clean = stripped(text)
        guard let data = clean.data(using: .utf8) else {
            throw WordGeneratorError.parsingFailed(clean)
        }
        struct Raw: Decodable {
            let civilian:   [String: String]
            let undercover: [String: String]
            let similarity: Double?
        }
        let raws: [Raw]
        if let arr = try? JSONDecoder().decode([Raw].self, from: data) {
            raws = arr
        } else if let dict = try? JSONDecoder().decode([String: [Raw]].self, from: data) {
            raws = dict.values.flatMap { $0 }
        } else {
            throw WordGeneratorError.parsingFailed(clean)
        }
        return raws.map {
            WordPair(civilian:   LocalizedWord(values: $0.civilian),
                     undercover: LocalizedWord(values: $0.undercover),
                     topic:      topic,
                     similarity: $0.similarity)
        }
    }

    // MARK: - Helpers

    private func cacheKey(language: AppLanguage, topic: String, difficulty: PairDifficulty) -> String {
        "\(language.rawValue)|\(topic)|\(difficulty.rawValue)"
    }

    private func stripped(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        if let start = s.firstIndex(of: "["), let end = s.lastIndex(of: "]"), start < end {
            s = String(s[start...end])
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
