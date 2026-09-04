//
//  WordPairPromptBuilder.swift
//  undercover
//
//  Constructs prompts for LLM-based word pair generation.
//  Emphasizes avoiding already-used concepts.
//

import Foundation

public enum WordPairPromptBuilder {

    static let systemPrompt = """
    You generate word pairs for the party game "Undercover".

    GAME RULES:
    1. Both concepts MUST belong to the requested topic
    2. Both concepts MUST be distinct entities (not variations)
    3. They must be similar enough that honest clues describe both
    4. NEVER pair a thing with its character, creator, location, sequel, alias, or variant
    5. NEVER use anything from the ALREADY USED list (this is CRITICAL)
    6. Use recognizable, well-known concepts
    7. Return ONLY JSON, no explanation

    GOOD PAIRS:
    - Naruto ↔ One Piece (both anime, shared themes)
    - Batman ↔ Sherlock Holmes (both detectives)
    - Nike ↔ Adidas (both shoe brands)

    BAD PAIRS:
    - Death Note ↔ Light Yagami (character from show, not distinct)
    - Naruto ↔ Naruto Uzumaki (same concept, different forms)
    - Apple ↔ Fruit (Apple is in Fruit category, not distinct level)

    SIMILARITY RANGE:
    - easy:   0.40–0.54 (loosely related)
    - medium: 0.55–0.69 (related, not obvious)
    - hard:   0.70–1.00 (closely related, tricky)

    Always return similarity as a DECIMAL NUMBER, never as text.

    OUTPUT FORMAT:
    [
      {"civilian": "Concept 1", "undercover": "Concept 2", "similarity": 0.65}
    ]

    Generate up to 6 pairs. Quality > Quantity.
    """

    /// Build a prompt with topic, difficulty, exclusions, and retry strategy.
    public static func build(
        topic: String,
        language: AppLanguage,
        difficultyLabel: String,
        excluding: Set<String>,
        attempt: Int
    ) -> String {

        let usedList = formatExcludingList(excluding)
        let strategy = retryStrategy(for: attempt)

        let outputLanguage: String = {
            switch language {
            case .english:
                return "English"
            case .french:
                return "French"
            case .spanish:
                return "Spanish"
            case .arabic:
                return "Arabic"
            case .tunisian:
                return "Tunisian Arabic"
            }
        }()

        return """
        TOPIC: \(topic)
        DIFFICULTY: \(difficultyLabel)
        OUTPUT LANGUAGE: \(outputLanguage)
        ATTEMPT: \(attempt)

        IMPORTANT LANGUAGE RULE:
        Return BOTH concepts in \(outputLanguage).
        Use the natural/common name in \(outputLanguage).
        Proper nouns, brand names, character names, anime titles, movie titles, etc.
        may remain unchanged when that is their commonly used name in \(outputLanguage).

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ALREADY USED — COMPLETE LIST (DO NOT USE ANY):
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        \(usedList)

        CRITICAL: The list above is complete. NEVER use ANY concept from it in any pair.

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        STRATEGY FOR THIS ATTEMPT:
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        \(strategy)

        Before returning each pair:
        ✓ Both concepts are from topic "\(topic)"
        ✓ Both are DISTINCT entities (not variations)
        ✓ NEITHER concept appears in the ALREADY USED list above
        ✓ Both concepts are written in \(outputLanguage)
        ✓ similarity is a DECIMAL NUMBER matching the difficulty
        ✓ Not a parent/child, character/creator, or alias relationship

        Generate up to 6 NEW pairs.

        Return JSON array only. No preamble.
        """
    }

    // MARK: - Helpers

    private static func formatExcludingList(
        _ excluding: Set<String>
    ) -> String {

        guard !excluding.isEmpty else {
            return "NONE — Generate freely from the topic."
        }

        return excluding
            .sorted()
            .enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
    }

    private static func retryStrategy(for attempt: Int) -> String {
        switch attempt {
        case 1:
            return """
            ATTEMPT 1 — Start fresh.
            Prefer well-known, recognizable concepts from the topic.
            Focus on quality pairs that clearly match the difficulty level.
            """

        case 2:
            return """
            ATTEMPT 2 — Many common concepts have been used.
            Look for less obvious but still recognizable concepts.
            Avoid obvious pairs; prioritize depth and uniqueness.
            Double-check that neither concept is in ALREADY USED.
            """

        default:
            return """
            ATTEMPT 3 — This topic may be partially exhausted.
            Focus on finding genuinely unique, creative pairs.
            Consider specialized or less common (but still valid) concepts.
            MOST IMPORTANT: Triple-check that NEITHER concept is ALREADY USED.
            Only return pairs you are CONFIDENT are new.
            """
        }
    }
}
