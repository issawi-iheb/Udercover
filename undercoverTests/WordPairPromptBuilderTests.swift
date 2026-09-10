//
//  WordPairPromptBuilderTests.swift
//  undercoverTests
//
import Testing
@testable import undercover

struct WordPairPromptBuilderTests {

    // MARK: - Basic Configuration

    @Test
    func build_includesBasicComponents() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: ["cat", "dog"],
            attempt: 1
        )

        #expect(prompt.contains("TOPIC: Animals"))
        #expect(prompt.contains("DIFFICULTY: Medium"))
        #expect(prompt.contains("OUTPUT LANGUAGE: English"))
        #expect(prompt.contains("ATTEMPT: 1"))
    }

    // MARK: - Languages

    @Test
    func build_supportsAllLanguages() {
        let cases: [(AppLanguage, String)] = [
            (.english, "English"),
            (.french, "French"),
            (.spanish, "Spanish"),
            (.arabic, "Arabic"),
            (.tunisian, "Tunisian Arabic")
        ]

        for (language, expectedLanguage) in cases {
            let prompt = WordPairPromptBuilder.build(
                topic: "Animals",
                language: language,
                difficultyLabel: "Medium",
                excluding: [],
                attempt: 1
            )

            #expect(
                prompt.contains(
                    "OUTPUT LANGUAGE: \(expectedLanguage)"
                )
            )

            #expect(
                prompt.contains(
                    "Return BOTH concepts in \(expectedLanguage)."
                )
            )

            #expect(
                prompt.contains(
                    "Use the natural/common name in \(expectedLanguage)."
                )
            )
        }
    }

    // MARK: - Difficulty

    @Test
    func build_preservesDifficultyLabel() {
        let difficulties = [
            "Easy",
            "Medium",
            "Hard"
        ]

        for difficulty in difficulties {
            let prompt = WordPairPromptBuilder.build(
                topic: "Animals",
                language: .english,
                difficultyLabel: difficulty,
                excluding: [],
                attempt: 1
            )

            #expect(
                prompt.contains(
                    "DIFFICULTY: \(difficulty)"
                )
            )
        }
    }

    // MARK: - Exclusions

    @Test
    func build_handlesEmptyExclusions() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [],
            attempt: 1
        )

        #expect(
            prompt.contains(
                "NONE — Generate freely from the topic."
            )
        )
    }

    @Test
    func build_includesExclusions() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [
                "cat",
                "dog"
            ],
            attempt: 1
        )

        #expect(
            prompt.contains(
                "ALREADY USED — COMPLETE LIST (DO NOT USE ANY):"
            )
        )

        #expect(prompt.contains("1. cat"))
        #expect(prompt.contains("2. dog"))

        #expect(
            prompt.contains(
                "CRITICAL: The list above is complete. NEVER use ANY concept from it in any pair."
            )
        )
    }

    @Test
    func build_sortsExclusions() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [
                "zebra",
                "apple",
                "monkey"
            ],
            attempt: 1
        )

        #expect(
            prompt.contains(
                "1. apple\n2. monkey\n3. zebra"
            )
        )
    }

    // MARK: - Retry Strategy

    @Test
    func build_attemptOneUsesCorrectStrategy() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [],
            attempt: 1
        )

        #expect(
            prompt.contains(
                "ATTEMPT 1 — Start fresh."
            )
        )

        #expect(
            prompt.contains(
                "Prefer well-known, recognizable concepts from the topic."
            )
        )

        #expect(
            prompt.contains(
                "Focus on quality pairs that clearly match the difficulty level."
            )
        )
    }

    @Test
    func build_attemptTwoUsesCorrectStrategy() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [],
            attempt: 2
        )

        #expect(
            prompt.contains(
                "ATTEMPT 2 — Many common concepts have been used."
            )
        )

        #expect(
            prompt.contains(
                "Look for less obvious but still recognizable concepts."
            )
        )

        #expect(
            prompt.contains(
                "Avoid obvious pairs; prioritize depth and uniqueness."
            )
        )

        #expect(
            prompt.contains(
                "Double-check that neither concept is in ALREADY USED."
            )
        )
    }

    @Test
    func build_attemptThreeUsesCorrectStrategy() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [],
            attempt: 3
        )

        #expect(
            prompt.contains(
                "ATTEMPT 3 — This topic may be partially exhausted."
            )
        )

        #expect(
            prompt.contains(
                "Focus on finding genuinely unique, creative pairs."
            )
        )

        #expect(
            prompt.contains(
                "Consider specialized or less common (but still valid) concepts."
            )
        )

        #expect(
            prompt.contains(
                "MOST IMPORTANT: Triple-check that NEITHER concept is ALREADY USED."
            )
        )
    }

    @Test
    func build_attemptGreaterThanThreeUsesFallbackStrategy() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [],
            attempt: 5
        )

        #expect(
            prompt.contains(
                "ATTEMPT 3 — This topic may be partially exhausted."
            )
        )

        #expect(
            prompt.contains(
                "Focus on finding genuinely unique, creative pairs."
            )
        )
    }

    // MARK: - Quality Rules

    @Test
    func build_includesQualityRules() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [],
            attempt: 1
        )

        #expect(
            prompt.contains(
                "Before returning each pair:"
            )
        )

        #expect(
            prompt.contains(
                "✓ Both concepts are from topic \"Animals\""
            )
        )

        #expect(
            prompt.contains(
                "✓ Both are DISTINCT entities (not variations)"
            )
        )

        #expect(
            prompt.contains(
                "✓ NEITHER concept appears in the ALREADY USED list above"
            )
        )

        #expect(
            prompt.contains(
                "✓ Both concepts are written in English"
            )
        )

        #expect(
            prompt.contains(
                "✓ similarity is a DECIMAL NUMBER matching the difficulty"
            )
        )

        #expect(
            prompt.contains(
                "✓ Not a parent/child, character/creator, or alias relationship"
            )
        )
    }

    // MARK: - Output Rules

    @Test
    func build_includesOutputRules() {
        let prompt = WordPairPromptBuilder.build(
            topic: "Animals",
            language: .english,
            difficultyLabel: "Medium",
            excluding: [],
            attempt: 1
        )

        #expect(
            prompt.contains(
                "Generate up to 6 NEW pairs."
            )
        )

        #expect(
            prompt.contains(
                "Return JSON array only. No preamble."
            )
        )
    }

    // MARK: - Topic Handling

    @Test
    func build_preservesSpecialCharactersInTopic() {
        let topics = [
            "C++ Programming",
            "Rock & Roll",
            "Movies & TV",
            "Science: Physics"
        ]

        for topic in topics {
            let prompt = WordPairPromptBuilder.build(
                topic: topic,
                language: .english,
                difficultyLabel: "Medium",
                excluding: [],
                attempt: 1
            )

            #expect(
                prompt.contains(
                    "TOPIC: \(topic)"
                )
            )

            #expect(
                prompt.contains(
                    "Both concepts are from topic \"\(topic)\""
                )
            )
        }
    }

    // MARK: - System Prompt

    @Test
    func systemPrompt_containsGameRules() {
        let prompt = WordPairPromptBuilder.systemPrompt

        #expect(
            prompt.contains(
                "You generate word pairs for the party game \"Undercover\"."
            )
        )

        #expect(
            prompt.contains(
                "Both concepts MUST belong to the requested topic"
            )
        )

        #expect(
            prompt.contains(
                "Both concepts MUST be distinct entities"
            )
        )

        #expect(
            prompt.contains(
                "NEVER use anything from the ALREADY USED list"
            )
        )

        #expect(
            prompt.contains(
                "Use recognizable, well-known concepts"
            )
        )

        #expect(
            prompt.contains(
                "Return ONLY JSON, no explanation"
            )
        )
    }

    @Test
    func systemPrompt_containsDifficultyRanges() {
        let prompt = WordPairPromptBuilder.systemPrompt

        #expect(
            prompt.contains(
                "easy:   0.40–0.54"
            )
        )

        #expect(
            prompt.contains(
                "medium: 0.55–0.69"
            )
        )

        #expect(
            prompt.contains(
                "hard:   0.70–1.00"
            )
        )
    }

    @Test
    func systemPrompt_containsOutputFormat() {
        let prompt = WordPairPromptBuilder.systemPrompt

        #expect(
            prompt.contains(
                "OUTPUT FORMAT:"
            )
        )

        #expect(
            prompt.contains(
                #"{"civilian": "Concept 1", "undercover": "Concept 2", "similarity": 0.65}"#
            )
        )

        #expect(
            prompt.contains(
                "Generate up to 6 pairs. Quality > Quantity."
            )
        )
    }
}
