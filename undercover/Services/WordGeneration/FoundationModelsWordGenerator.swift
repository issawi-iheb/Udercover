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

    private var cache: [String: [WordPair]] = [:]

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

        let normalizedTopic = topic
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cacheKey =
            "\(language.rawValue)|\(normalizedTopic)|\(difficulty.rawValue)"

        let excluded = Set(
            excluding.map(Self.normalize)
        )

        print("""
        🧠 FoundationModels
        Topic: \(normalizedTopic)
        Difficulty: \(difficulty.rawValue)
        Excluded: \(excluding.sorted().joined(separator: ", "))
        """)

        // ---------------------------------------------------------
        // 1. CHECK CACHE
        // ---------------------------------------------------------

        if let pair = firstAvailablePair(
            from: cache[cacheKey] ?? [],
            excluding: excluded
        ) {

            print("""
            ✅ Using cached generated pair:
            \(pair.civilian.values["en"] ?? "?")
            /
            \(pair.undercover.values["en"] ?? "?")
            """)

            return pair
        }

        // ---------------------------------------------------------
        // 2. GENERATE UNTIL WE FIND A NEW PAIR
        // ---------------------------------------------------------

        let maxAttempts = 10

        for attempt in 1...maxAttempts {

            print(
                "🤖 Generating pairs — attempt \(attempt)/\(maxAttempts)"
            )

            do {

                let freshPairs = try await fetchViaLLM(
                    topic: normalizedTopic,
                    language: language,
                    difficulty: difficulty,
                    excluding: excluding,
                    attempt: attempt
                )

                print(
                    "🤖 Model returned \(freshPairs.count) valid candidates"
                )

                // -------------------------------------------------
                // Find a genuinely unused pair
                // -------------------------------------------------

                if let pair = firstAvailablePair(
                    from: freshPairs,
                    excluding: excluded
                ) {

                    print("""
                    ✅ Selected NEW generated pair:
                    \(pair.civilian.values["en"] ?? "?")
                    /
                    \(pair.undercover.values["en"] ?? "?")
                    """)

                    // -------------------------------------------------
                    // Cache ONLY genuinely new pairs.
                    // -------------------------------------------------

                    var cachedPairs = cache[cacheKey, default: []]

                    let existingConcepts = Set(
                        cachedPairs.flatMap { pair in
                            [
                                Self.normalize(
                                    pair.civilian.values["en"]
                                ),
                                Self.normalize(
                                    pair.undercover.values["en"]
                                )
                            ]
                        }
                    )

                    let newPairs = freshPairs.filter { candidate in

                        let civilian = Self.normalize(
                            candidate.civilian.values["en"]
                        )

                        let undercover = Self.normalize(
                            candidate.undercover.values["en"]
                        )

                        guard !excluded.contains(civilian),
                              !excluded.contains(undercover)
                        else {
                            return false
                        }

                        return !existingConcepts.contains(civilian) &&
                               !existingConcepts.contains(undercover)
                    }

                    cachedPairs.append(contentsOf: newPairs)

                    if cachedPairs.count > 30 {
                        cachedPairs = Array(
                            cachedPairs.suffix(30)
                        )
                    }

                    cache[cacheKey] = cachedPairs

                    return pair
                }

                print("""
                ⚠️ Attempt \(attempt):
                All generated pairs were already used.
                """)

            } catch {

                print("""
                ⚠️ Attempt \(attempt) failed:
                \(error.localizedDescription)
                """)

                // Don't immediately fail.
                // Give the model another chance.
                if attempt == maxAttempts {
                    throw error
                }
            }
        }

        throw WordGeneratorError.noPairsAvailable
    }

    // MARK: - Pair Filtering

    private nonisolated func firstAvailablePair(
        from pairs: [WordPair],
        excluding excluded: Set<String>
    ) -> WordPair? {

        for pair in pairs {

            let civilian = Self.normalize(
                pair.civilian.values["en"]
            )

            let undercover = Self.normalize(
                pair.undercover.values["en"]
            )

            let civilianExcluded =
                Self.matchesExcluded(
                    civilian,
                    excluded: excluded
                )

            let undercoverExcluded =
                Self.matchesExcluded(
                    undercover,
                    excluded: excluded
                )

            if civilianExcluded || undercoverExcluded {

                let matchedSide: String

                if civilianExcluded && undercoverExcluded {
                    matchedSide = "civilian + undercover"
                } else if civilianExcluded {
                    matchedSide = "civilian"
                } else {
                    matchedSide = "undercover"
                }

                print("""
                🚫 Rejected pair:
                \(pair.civilian.values["en"] ?? "?")
                /
                \(pair.undercover.values["en"] ?? "?")

                Match:
                \(matchedSide)
                """)

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

            let candidateTokens = Set(
                candidate.split(separator: " ")
                    .map(String.init)
            )

            let excludedTokens = Set(
                excludedValue.split(separator: " ")
                    .map(String.init)
            )

            // Example:
            // "naruto" vs "naruto uzumaki"
            //
            // "demon slayer" vs
            // "demon slayer kimetsu no yaiba"

            if candidateTokens.isSubset(of: excludedTokens) ||
               excludedTokens.isSubset(of: candidateTokens) {

                return true
            }
        }

        return false
    }

    // MARK: - LLM Query

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

        let topicValue = topic.isEmpty
            ? DefaultTopic.value
            : topic

        let prompt = WordPairPromptBuilder.build(
            topic: topicValue,
            difficultyLabel: difficulty.rawValue,
            excluding: excluding,
            attempt: attempt
        )

        print("""
        📝 Prompt:
        \(prompt)
        """)

        let response = try await session.respond(
            to: prompt
        )

        print("""
        🤖 Raw model response:
        \(response.content)
        """)

        return try Self.parseAndValidateJSON(
            response.content,
            topic: topicValue,
            difficulty: difficulty
        )

#else

        throw WordGeneratorError.unavailable(
            "Apple Intelligence is not available on this platform."
        )

#endif
    }

    // MARK: - JSON Parsing & Validation

    private nonisolated static func parseAndValidateJSON(
        _ text: String,
        topic: String,
        difficulty: PairDifficulty
    ) throws -> [WordPair] {

        var rejectionReasons: [String: Int] = [:]

        var clean = text
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

        // ---------------------------------------------------------
        // Extract JSON array
        // ---------------------------------------------------------

        if let start = clean.firstIndex(of: "["),
           let end = clean.lastIndex(of: "]"),
           start < end {

            clean = String(
                clean[start...end]
            )
        }

        guard let data = clean.data(
            using: .utf8
        ) else {

            throw WordGeneratorError.parsingFailed(
                clean
            )
        }

        // ---------------------------------------------------------
        // Flexible similarity
        //
        // Small models sometimes return:
        //
        // "similarity": 0.75
        //
        // but sometimes:
        //
        // "similarity": "genre"
        //
        // We do NOT let one bad pair destroy the entire response.
        // ---------------------------------------------------------

        struct RawPair: Decodable {

            let civilian: String
            let undercover: String
            let similarity: FlexibleDouble?
        }

        guard let rawPairs = try? JSONDecoder().decode(
            [RawPair].self,
            from: data
        ) else {

            print("""
            ❌ Could not decode model response:
            \(clean)
            """)

            throw WordGeneratorError.parsingFailed(
                clean
            )
        }

        var seen = Set<String>()
        var pairs: [WordPair] = []

        // ---------------------------------------------------------
        // Validate candidates
        // ---------------------------------------------------------

        for raw in rawPairs {

            let civilianEN = normalize(
                raw.civilian
            )

            let undercoverEN = normalize(
                raw.undercover
            )

            // -----------------------------------------------------
            // 1. Empty
            // -----------------------------------------------------

            guard !civilianEN.isEmpty,
                  !undercoverEN.isEmpty else {

                rejectionReasons["empty", default: 0] += 1
                continue
            }

            // -----------------------------------------------------
            // 2. Same concept
            // -----------------------------------------------------

            guard civilianEN != undercoverEN else {

                rejectionReasons["same_concept", default: 0] += 1
                continue
            }

            // -----------------------------------------------------
            // 3. Token containment
            // -----------------------------------------------------

            let civilianTokens = Set(
                civilianEN
                    .split(separator: " ")
                    .map(String.init)
            )

            let undercoverTokens = Set(
                undercoverEN
                    .split(separator: " ")
                    .map(String.init)
            )

            if civilianTokens.isSubset(
                of: undercoverTokens
            ) ||
            undercoverTokens.isSubset(
                of: civilianTokens
            ) {

                rejectionReasons["token_containment", default: 0] += 1
                continue
            }

            // -----------------------------------------------------
            // 4. Duplicate inside response
            // -----------------------------------------------------

            guard !seen.contains(civilianEN),
                  !seen.contains(undercoverEN) else {

                rejectionReasons["duplicate", default: 0] += 1
                continue
            }

            // -----------------------------------------------------
            // 5. Similarity
            // -----------------------------------------------------

            guard let similarity = raw.similarity?.value else {

                rejectionReasons["invalid_similarity", default: 0] += 1

                print("""
                🚫 Rejected pair:
                \(raw.civilian) / \(raw.undercover)
                Reason: invalid similarity
                """)

                continue
            }

            guard similarity >= 0.0,
                  similarity <= 1.0 else {

                rejectionReasons["invalid_similarity", default: 0] += 1
                continue
            }

            // -----------------------------------------------------
            // 6. Difficulty validation
            // -----------------------------------------------------

            let validRange = difficulty.scoreRange

            guard validRange.contains(similarity) else {

                rejectionReasons["wrong_difficulty", default: 0] += 1

                print("""
                🚫 Rejected pair:
                \(raw.civilian) / \(raw.undercover)
                Similarity: \(similarity)
                Expected: \(validRange)
                """)

                continue
            }

            // -----------------------------------------------------
            // 7. Build WordPair
            // -----------------------------------------------------

            let civilian = LocalizedWord(
                values: buildTranslations(
                    raw.civilian
                )
            )

            let undercover = LocalizedWord(
                values: buildTranslations(
                    raw.undercover
                )
            )

            let pair = WordPair(
                civilian: civilian,
                undercover: undercover,
                topic: topic,
                similarity: similarity
            )

            pairs.append(pair)

            seen.insert(civilianEN)
            seen.insert(undercoverEN)
        }

        // ---------------------------------------------------------
        // Logging
        // ---------------------------------------------------------

        print("""
        🔎 Validation:
        Generated: \(rawPairs.count)
        Valid: \(pairs.count)
        """)

        if !rejectionReasons.isEmpty {

            let reasons = rejectionReasons
                .sorted {
                    $0.value > $1.value
                }

            for (reason, count) in reasons {
                print(
                    "  - \(reason): \(count)"
                )
            }
        }

        guard !pairs.isEmpty else {

            print("""
            ❌ No valid pairs generated
            Topic: \(topic)
            Difficulty: \(difficulty.rawValue)
            """)

            throw WordGeneratorError.noPairsAvailable
        }

        print("""
        ✅ Generated \(pairs.count) valid pairs
        Topic: \(topic)
        Difficulty: \(difficulty.rawValue)
        """)

        return pairs
    }

    // MARK: - Flexible Similarity

    private struct FlexibleDouble: Decodable {

        let value: Double?

        init(from decoder: Decoder) throws {

            let container = try decoder.singleValueContainer()

            if let number = try? container.decode(Double.self) {
                value = number
                return
            }

            if let string = try? container.decode(String.self),
               let number = Double(string) {

                value = number
                return
            }

            // Example:
            // "similarity": "genre"
            //
            // We don't fail the whole JSON.
            // This individual pair will simply be rejected.

            value = nil
        }
    }

    // MARK: - Normalization

    private nonisolated static func normalize(
        _ value: String?
    ) -> String {

        guard let value else {
            return ""
        }

        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(
                options: .diacriticInsensitive,
                locale: .current
            )

        return normalized
            .split { character in
                character.isWhitespace ||
                character.isPunctuation ||
                character.isSymbol
            }
            .joined(separator: " ")
    }

    // MARK: - Translations

    private nonisolated static func buildTranslations(
        _ value: String
    ) -> [String: String] {

        [
            "en": value,
            "fr": value,
            "es": value,
            "ar": value,
            "tn": value
        ]
    }
}
