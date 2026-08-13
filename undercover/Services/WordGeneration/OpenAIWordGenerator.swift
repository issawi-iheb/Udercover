//
//  OpenAIWordGenerator.swift
//  undercoverApp
//

import Foundation

public actor OpenAIWordGenerator: WordGeneratorProtocol {

    public let generatorName = "ChatGPT (OpenAI)"

    public var isAvailable: Bool {
        let key = Config.openAIAPIKey
        return key.hasPrefix("sk-") && key != "sk-proj-REPLACE_ME"
    }

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var cache: [String: [WordPair]] = [:]

    // MARK: - Protocol

    public func randomPair(
        topic:      String,
        language:   AppLanguage,
        difficulty: PairDifficulty,
        excluding:  Set<String>
    ) async throws -> WordPair {
        guard isAvailable else {
            throw WordGeneratorError.unavailable("OpenAI API key not configured.")
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
        case .easy:   diffDesc = "very different, easy to distinguish"
        case .medium: diffDesc = "related but noticeably different"
        case .hard:   diffDesc = "very close, tricky to distinguish"
        }

        let avoidClause = excluding.isEmpty ? "" :
            "\nAvoid: \(excluding.sorted().joined(separator: ", "))."

        let prompt = """
        Generate 15 word pairs for the party game "Undercover".
        Topic: \(topic.isEmpty ? "any everyday topic" : topic)
        Language: \(language.promptLabel)
        Difficulty: \(diffDesc)\(avoidClause)

        Rules: semantically related but distinct. Include all 5 translations (en, ar, fr, es, tn).
        Return ONLY raw JSON — no markdown:
        [{"civilian":{"en":"","ar":"","fr":"","es":"","tn":""},"undercover":{"en":"","ar":"","fr":"","es":"","tn":""},"similarity":0.65}]
        """

        let body: [String: Any] = [
            "model":    "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]]
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json",               forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(Config.openAIAPIKey)",  forHTTPHeaderField: "Authorization")
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
        struct Response: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let resp = try JSONDecoder().decode(Response.self, from: data)
        guard let content = resp.choices.first?.message.content else {
            throw WordGeneratorError.invalidResponse
        }
        return try parseJSON(content, topic: topic)
    }

    private func parseJSON(_ text: String, topic: String) throws -> [WordPair] {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
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
        return try JSONDecoder().decode([Raw].self, from: d).map {
            WordPair(civilian:   LocalizedWord(values: $0.civilian),
                     undercover: LocalizedWord(values: $0.undercover),
                     topic:      topic,
                     similarity: $0.similarity)
        }
    }

    private func cacheKey(language: AppLanguage, topic: String, difficulty: PairDifficulty) -> String {
        "\(language.rawValue)|\(topic)|\(difficulty.rawValue)"
    }
}
