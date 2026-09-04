//
//  FoundationModelsWordGenerator.swift
//  undercoverApp
//
//  Uses Apple's on-device FoundationModels.
//  iOS 26+ / Apple Intelligence.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public actor FoundationModelsWordGenerator: WordGeneratorProtocol {

    public let generatorName =
        "Apple Intelligence (On-Device)"

    // MARK: - Availability

    public var isAvailable: Bool {

#if canImport(FoundationModels)

        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }

#endif

        return false
    }

    // MARK: - Public API

    public func randomPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair {

        guard isAvailable else {
            throw WordGeneratorError.unavailable(
                "Apple Intelligence is not available on this device."
            )
        }

        let normalizedTopic =
            topic.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let normalizedExclusions = Set(
            excluding.map(NormalizationUtility.normalize)
        )

        print("""
        🧠 [FoundationModels]
        Topic: \(normalizedTopic)
        Difficulty: \(difficulty.rawValue)
        Exclusions: \(normalizedExclusions.count)
        """)

        let maxAttempts = 10

        for attempt in 1...maxAttempts {

            guard !Task.isCancelled else {
                throw CancellationError()
            }

            print(
                "🤖 [FoundationModels] Attempt \(attempt)/\(maxAttempts)"
            )

            do {

                let candidates = try await fetchViaLLM(
                    topic: normalizedTopic,
                    language: language,
                    difficulty: difficulty,
                    excluding: normalizedExclusions,
                    attempt: attempt
                )

                print(
                    "🤖 Model returned \(candidates.count) valid candidates"
                )

                if let pair = firstAvailablePair(
                    from: candidates,
                    language: language,
                    excluding: normalizedExclusions
                ) {

                    print("""
                    ✅ [FoundationModels] Selected:
                    \(pair.civilian.localized(for: language))
                    /
                    \(pair.undercover.localized(for: language))
                    """)

                    return pair
                }

                print(
                    "⚠️ All generated candidates conflict with exclusions"
                )

            } catch is CancellationError {

                throw CancellationError()

            } catch {

                print("""
                ⚠️ [FoundationModels] Attempt \(attempt) failed:
                \(error.localizedDescription)
                """)

                if attempt == maxAttempts {
                    throw error
                }
            }
        }

        throw WordGeneratorError.noPairsAvailable
    }

    // MARK: - Candidate Selection

    private nonisolated func firstAvailablePair(
        from pairs: [WordPair],
        language: AppLanguage,
        excluding excluded: Set<String>
    ) -> WordPair? {

        for pair in pairs {

            let civilian = NormalizationUtility.normalize(
                pair.civilian.localized(for: language)
            )

            let undercover = NormalizationUtility.normalize(
                pair.undercover.localized(for: language)
            )

            guard !civilian.isEmpty,
                  !undercover.isEmpty else {
                continue
            }

            guard !Self.matchesExcluded(
                civilian,
                excluded: excluded
            ) else {
                continue
            }

            guard !Self.matchesExcluded(
                undercover,
                excluded: excluded
            ) else {
                continue
            }

            return pair
        }

        return nil
    }

    // MARK: - Exclusion Matching

    private nonisolated static func matchesExcluded(
        _ candidate: String,
        excluded: Set<String>
    ) -> Bool {

        guard !candidate.isEmpty else {
            return true
        }

        for excludedValue in excluded {

            if candidate == excludedValue {
                return true
            }

            let candidateTokens =
                Set(
                    candidate
                        .split(separator: " ")
                        .map(String.init)
                )

            let excludedTokens =
                Set(
                    excludedValue
                        .split(separator: " ")
                        .map(String.init)
                )

            if candidateTokens.isSubset(
                of: excludedTokens
            ) ||
            excludedTokens.isSubset(
                of: candidateTokens
            ) {
                return true
            }
        }

        return false
    }

    // MARK: - LLM

    private func fetchViaLLM(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>,
        attempt: Int
    ) async throws -> [WordPair] {

#if canImport(FoundationModels)

        guard #available(iOS 26.0, *) else {
            throw WordGeneratorError.unavailable(
                "Apple Intelligence requires iOS 26 or newer."
            )
        }

        let session = LanguageModelSession(
            instructions: WordPairPromptBuilder.systemPrompt
        )

        let prompt =
            WordPairPromptBuilder.build(
                topic: topic.isEmpty
                    ? DefaultTopic.value
                : topic, language: language,
                difficultyLabel: difficulty.rawValue,
                excluding: excluding,
                attempt: attempt
            )

        print("""
        📝 [FoundationModels] Prompt:
        \(prompt)
        """)

        let response =
            try await session.respond(
                to: prompt
            )

        print("""
        🤖 [FoundationModels] Raw response:
        \(response.content)
        """)

        return try Self.parseAndValidateJSON(
            response.content,
            topic: topic,
            language: language,
            difficulty: difficulty
        )

#else

        throw WordGeneratorError.unavailable(
            "FoundationModels is not available on this platform."
        )

#endif
    }

    // MARK: - JSON Parsing

    private nonisolated static func parseAndValidateJSON(
        _ text: String,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) throws -> [WordPair] {

        struct RawPair: Decodable {

            let civilian: String
            let undercover: String
            let similarity: FlexibleDouble?
        }

        var clean =
            text
                .replacingOccurrences(
                    of: "```json",
                    with: ""
                )
                .replacingOccurrences(
                    of: "```JSON",
                    with: ""
                )
                .replacingOccurrences(
                    of: "```",
                    with: ""
                )
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if let start = clean.firstIndex(of: "["),
           let end = clean.lastIndex(of: "]"),
           start < end {

            clean = String(
                clean[start...end]
            )
        }

        guard let data =
                clean.data(using: .utf8)
        else {
            throw WordGeneratorError.parsingFailed(clean)
        }

        guard let rawPairs =
                try? JSONDecoder().decode(
                    [RawPair].self,
                    from: data
                )
        else {

            print(
                "❌ Could not decode LLM response:\n\(clean)"
            )

            throw WordGeneratorError.parsingFailed(clean)
        }

        var seen = Set<String>()
        var pairs: [WordPair] = []

        for raw in rawPairs {

            let civilianEN =
            NormalizationUtility.normalize(raw.civilian)

            let undercoverEN =
            NormalizationUtility.normalize(raw.undercover)

            guard !civilianEN.isEmpty,
                  !undercoverEN.isEmpty else {
                continue
            }

            guard civilianEN != undercoverEN else {
                continue
            }

            let civilianTokens =
                Set(
                    civilianEN
                        .split(separator: " ")
                        .map(String.init)
                )

            let undercoverTokens =
                Set(
                    undercoverEN
                        .split(separator: " ")
                        .map(String.init)
                )

            guard !civilianTokens.isSubset(
                of: undercoverTokens
            ),
            !undercoverTokens.isSubset(
                of: civilianTokens
            ) else {
                continue
            }

            guard !seen.contains(civilianEN),
                  !seen.contains(undercoverEN) else {
                continue
            }

            guard let similarity =
                    raw.similarity?.value,
                  similarity >= 0.0,
                  similarity <= 1.0 else {
                continue
            }

            guard difficulty.scoreRange.contains(
                similarity
            ) else {
                continue
            }

            let pair =
                WordPair(
                    civilian: LocalizedWord(
                        values: [
                            language.rawValue: raw.civilian
                        ]
                    ),
                    undercover: LocalizedWord(
                        values: [
                            language.rawValue: raw.undercover
                        ]
                    ),
                    topic: topic,
                    similarity: similarity
                )

            pairs.append(pair)

            seen.insert(civilianEN)
            seen.insert(undercoverEN)
        }

        guard !pairs.isEmpty else {
            throw WordGeneratorError.noPairsAvailable
        }

        print(
            "✅ [FoundationModels] Valid pairs: \(pairs.count)"
        )

        return pairs
    }

    // MARK: - Flexible Double

    private struct FlexibleDouble: Decodable {

        let value: Double?

        init(from decoder: Decoder) throws {

            let container =
                try decoder.singleValueContainer()

            if let number =
                try? container.decode(Double.self) {

                value = number
                return
            }

            if let string =
                try? container.decode(String.self),
               let number = Double(string) {

                value = number
                return
            }

            value = nil
        }
    }
}
