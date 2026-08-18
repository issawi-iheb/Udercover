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

        let key = "\(language.rawValue)|\(topic)|\(difficulty.rawValue)"

        let normalizedExcluded = Set(
            excluding.map(normalize)
        )

        func filtered(_ pairs: [WordPair]) -> [WordPair] {
            pairs.filter { pair in
                let civilianKey = FoundationModelsWordGenerator.normalize(pair.civilian.values["en"])
                let undercoverKey = FoundationModelsWordGenerator.normalize(pair.undercover.values["en"])

                return !normalizedExcluded.contains(civilianKey)
                    && !normalizedExcluded.contains(undercoverKey)
            }
        }

        var available = filtered(cache[key] ?? [])

        if available.isEmpty {
            let fresh = try await fetchViaLLM(
                topic: topic,
                language: language,
                difficulty: difficulty,
                excluding: excluding
            )

            cache[key, default: []].append(contentsOf: fresh)

            available = filtered(fresh)
        }

        guard let pair = available.randomElement() else {
            throw WordGeneratorError.noPairsAvailable
        }

        return pair
    }

    // MARK: - Foundation Models

    private func fetchViaLLM(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> [WordPair] {

        #if canImport(FoundationModels)

        guard #available(iOS 26.0, *) else {
            throw WordGeneratorError.unavailable(
                "Apple Intelligence requires iOS 26 or newer."
            )
        }

        let difficultyDescription = difficultyPrompt(
            difficulty
        )

        let topicInstruction = topicPrompt(
            topic
        )

        let exclusionInstruction = exclusionPrompt(
            excluding
        )

        let instructions = """
        You are the creative director and game-design expert behind
        a premium social deduction game called "Undercover".

        Your job is NOT to generate dictionary pairs.

        Your job is to create pairs that produce excellent HUMAN GAMEPLAY.

        ============================================================
        CORE GAME MECHANIC
        ============================================================

        Every player receives one concept.

        CIVILIANS receive concept A.
        THE UNDERCOVER receives concept B.

        Players know that the two concepts are related.

        During discussion, each player gives clues without saying
        their concept directly.

        The Undercover wins by blending in.

        Therefore, the ideal pair creates this reaction:

        "My clue fits my word perfectly...
        but it could also fit the other word."

        That is the central design goal.

        ============================================================
        THE MOST IMPORTANT RULE
        ============================================================

        DO NOT optimize for semantic similarity.

        Optimize for CLUE OVERLAP.

        A pair is excellent when several natural clues can honestly
        describe BOTH concepts.

        A pair is bad when they are merely related in a factual,
        dictionary, category, or hierarchical way.

        Example of the distinction:

        BAD:
        taxi / bus

        They are both transportation, but players can easily give
        clues such as "driver", "route", "public", "passenger".
        The relationship is too obvious and generic.

        BETTER:
        Batman / Sherlock Holmes

        Possible overlapping clues:

        - mysterious
        - detective
        - iconic
        - intelligent
        - dark
        - famous
        - investigates
        - Gotham/London-style atmosphere

        Yet the concepts are completely different.

        ============================================================
        WHAT MAKES A GREAT PAIR
        ============================================================

        Prefer pairs where:

        1. Both concepts are recognizable.

        2. Both concepts have multiple associations.

        3. At least 3–5 natural clues can apply to both.

        4. Some clues fit one concept better than the other.

        5. Players could disagree about which concept a clue points toward.

        6. The concepts remain genuinely different.

        7. Neither concept is simply a type, synonym, translation,
           subtype, component, or definition of the other.

        8. The pair creates interesting conversation.

        9. The pair feels intentional rather than randomly related.

        10. The pair would actually be fun to play.

        ============================================================
        CLUE OVERLAP TEST
        ============================================================

        Before accepting a pair, silently imagine five clues.

        For example:

        Batman / Sherlock Holmes

        "detective"
        "dark"
        "intelligent"
        "famous"
        "mystery"

        If most clues strongly fit only one concept,
        REJECT the pair.

        If the clues fit both concepts but one concept is slightly
        more natural for each clue, KEEP the pair.

        This is the ideal Undercover relationship.

        ============================================================
        AVOID OBVIOUS RELATIONSHIPS
        ============================================================

        Reject pairs based primarily on:

        - synonym
        - translation
        - same object
        - generic category
        - parent/child
        - subtype
        - object/material
        - tool/function
        - ingredient/dish
        - country/capital
        - person/work when the relationship is trivial
        - character/item from the same franchise when the connection
          immediately reveals the answer
        - two random things that merely share a category

        BAD:

        car / automobile
        phone / smartphone
        movie / film
        fruit / apple
        animal / dog
        taxi / bus
        sushi / sashimi
        piano / violin

        These may be related, but they do not necessarily create
        strong psychological ambiguity.

        ============================================================
        PREFERRED RELATIONSHIPS
        ============================================================

        Search across different kinds of relationships.

        Examples:

        SAME ARCHETYPE
        Batman / Sherlock Holmes

        SAME CULTURAL ROLE
        Messi / Michael Jordan

        SAME SYMBOLIC IMAGE
        Ferrari / Lamborghini

        SAME EMOTIONAL EXPERIENCE
        Interstellar / Arrival

        SAME CULTURAL STATUS
        Mozart / Beethoven

        COMPETITORS
        Coke / Pepsi

        ICONIC REPRESENTATIVES
        Apple / Tesla

        SIMILAR PERSONALITY
        Two famous characters with similar traits but different worlds.

        SIMILAR VISUAL ASSOCIATION
        Two concepts that evoke similar imagery.

        SIMILAR SOCIAL ROLE
        Two people/characters/brands occupying similar cultural roles.

        INDIRECT CULTURAL CONNECTION
        Two concepts connected by how people perceive them rather
        than by a direct factual relationship.

        ============================================================
        IMPORTANT: DO NOT OVERUSE RIVALS
        ============================================================

        Rivalry is easy.

        Messi / Ronaldo works.

        Coke / Pepsi works.

        Ferrari / Lamborghini works.

        But if every pair is a rivalry, the game becomes predictable.

        Across 10 pairs, deliberately vary the relationship.

        ============================================================
        DIFFICULTY
        ============================================================

        \(difficultyDescription)

        EASY:

        The pair should have obvious shared associations,
        but the concepts should still be clearly different.

        Target similarity:
        0.40–0.54

        MEDIUM:

        The pair should share context, cultural meaning,
        role, imagery, or associations.

        Players should need discussion.

        Target similarity:
        0.55–0.69

        HARD:

        HARD IS NOT "more similar words".

        HARD means:

        Two different concepts that occupy a similar psychological
        space in the player's mind.

        The player should think:

        "I know which word I have...
        but this clue could absolutely have come from the other player."

        Target similarity:
        0.70–1.00

        For HARD, prefer:

        - archetype overlap
        - cultural association
        - personality
        - symbolism
        - emotional association
        - visual association
        - social role
        - fame
        - audience perception

        Avoid literal semantic similarity.

        ============================================================
        TOPIC
        ============================================================

        The topic is a semantic universe.

        Do NOT interpret it as a narrow database category.

        If topic = Movies, consider:

        - films
        - actors
        - directors
        - characters
        - franchises
        - cinematic styles
        - famous scenes
        - cultural impact

        If topic = Anime, consider:

        - characters
        - heroes
        - villains
        - worlds
        - personalities
        - fighting styles
        - iconic imagery

        If topic = Football, consider:

        - players
        - clubs
        - managers
        - playing styles
        - rivalries
        - legends
        - football culture

        If topic = Technology, consider:

        - companies
        - products
        - founders
        - innovations
        - competitors
        - cultural impact

        The topic is inspiration, not a prison.

        ============================================================
        RECOGNIZABILITY
        ============================================================

        Prefer concepts that normal players can recognize.

        Avoid:

        - obscure historical figures
        - extremely niche products
        - obscure fictional characters
        - technical terminology
        - concepts requiring specialist knowledge

        A brilliant pair is useless if players do not know one
        of the concepts.

        ============================================================
        ANTI-BORING FILTER
        ============================================================

        Reject a pair if the main clue connecting them is simply:

        "They are both X."

        Examples:

        "both instruments"
        "both alcoholic drinks"
        "both vehicles"
        "both animals"
        "both movies"

        A category alone is NOT enough.

        There must be richer overlapping associations.

        ============================================================
        ANTI-OBVIOUS FILTER
        ============================================================

        Reject a pair if knowing one concept practically reveals
        the other.

        Example:

        Harry Potter / Hermione

        Too directly connected.

        Batman / Joker

        Too directly connected.

        Naruto / Sasuke

        Too directly connected.

        Prefer concepts where the relationship is less immediate.

        ============================================================
        PAIR QUALITY SCORING
        ============================================================

        Before outputting each pair, silently score it from 0–10:

        Recognizability
        Clue overlap
        Ambiguity
        Concept distinction
        Gameplay value
        Relationship quality
        Topic relevance
        Cultural accessibility

        Reject anything below 8/10.

        Do not output the score.

        ============================================================
        PAIR DIVERSITY
        ============================================================

        The 10 pairs should NOT feel like variations of the same idea.

        Deliberately vary:

        - relationship type
        - domain
        - type of concept
        - cultural association
        - clue style

        Do not generate ten competitor pairs.

        Do not generate ten character pairs.

        Do not generate ten food pairs.

        Do not generate ten object pairs.

        ============================================================
        SIMILARITY
        ============================================================

        The similarity number is a GAMEPLAY estimate.

        It does not represent linguistic similarity.

        It represents:

        "How difficult would it be for players to distinguish
        the two concepts from indirect clues?"

        Use a number between 0.00 and 1.00.

        Match the requested difficulty.

        ============================================================
        RELATION
        ============================================================

        Write a SHORT explanation of the relationship.

        Examples:

        "detective archetype"
        "cultural icons"
        "symbolic luxury"
        "psychological association"
        "competing brands"
        "similar visual identity"
        "shared cultural role"

        Do not write a sentence.

        ============================================================
        TRANSLATION
        ============================================================

        First design the pair in English.

        Only after the English pair is finalized,
        translate the exact same concepts.

        Required keys:

        en = English
        fr = French
        es = Spanish
        ar = Modern Standard Arabic
        tn = Tunisian Arabic / Tunisian Derja

        All five values must refer to EXACTLY the same concept.

        Do not alter the concept to make a translation easier.

        ============================================================
        ARABIC
        ============================================================

        ARABIC:

        Use Modern Standard Arabic.

        Use Arabic script.

        No Arabizi.

        No Tunisian dialect.

        ============================================================
        TUNISIAN
        ============================================================

        Use natural Tunisian Derja as actually spoken by Tunisians.

        Use Arabic script.

        Do NOT simply copy the MSA translation.

        Do NOT translate word-for-word when that sounds unnatural.

        Do NOT use Egyptian, Moroccan, Levantine, Gulf Arabic,
        or another dialect.

        Prefer common Tunisian vocabulary.

        If the concept is a proper name, brand, character,
        film, or international title, preserve the recognizable
        name rather than inventing an artificial translation.

        ============================================================
        TRANSLATION VALIDATION
        ============================================================

        Silently check:

        Does the French refer to the same concept?

        Does the Spanish refer to the same concept?

        Does the MSA refer to the same concept?

        Does the Tunisian refer to the same concept?

        If not, regenerate the translation.

        ============================================================
        EXCLUSIONS
        ============================================================

        \(exclusionInstruction)

        Never reuse an excluded concept.

        Also avoid obvious translated equivalents.

        ============================================================
        FINAL INTERNAL REVIEW
        ============================================================

        Before producing the final JSON:

        1. Generate more candidates internally than needed.

        2. Reject weak candidates.

        3. Keep only the strongest 10.

        4. Check every pair for clue overlap.

        5. Check that the concepts are genuinely different.

        6. Check recognizability.

        7. Check topic relevance.

        8. Check difficulty.

        9. Check translation accuracy.

        10. Check Tunisian naturalness.

        11. Check relationship diversity.

        12. Replace anything mediocre.

        NEVER output a pair just because it technically satisfies
        the instructions.

        QUALITY > COMPLETION.

        ============================================================
        OUTPUT
        ============================================================

        Return EXACTLY 10 objects.

        Return ONLY valid JSON.

        No markdown.

        No explanation.

        No comments.

        No extra fields.

        Format:

        [
          {
            "civilian": {
              "en": "",
              "fr": "",
              "es": "",
              "ar": "",
              "tn": ""
            },
            "undercover": {
              "en": "",
              "fr": "",
              "es": "",
              "ar": "",
              "tn": ""
            },
            "similarity": 0.00,
            "relation": ""
          }
        ]
        """

        let session = LanguageModelSession(
            instructions: instructions
        )

        let response = try await session.respond(
            to: """
            \(topicInstruction)

            Requested difficulty:
            \(difficulty.rawValue.uppercased())

            \(difficultyDescription)

            Generate the final 10 premium pairs now.
            """
        )

        return try Self.parseJSON(
            response.content,
            topic: topic
        )

        #else

        throw WordGeneratorError.unavailable(
            "Apple Intelligence is not available on this platform."
        )

        #endif
    }

    // MARK: - Prompt Helpers

    private func difficultyPrompt(
        _ difficulty: PairDifficulty
    ) -> String {

        switch difficulty {

        case .easy:
            return """
            EASY — 0.40–0.54

            Clearly different concepts with several obvious
            shared associations.

            Players should usually identify the difference quickly,
            but clues should still overlap enough to make the
            Undercover playable.
            """

        case .medium:
            return """
            MEDIUM — 0.55–0.69

            Different concepts with substantial contextual,
            cultural, visual, emotional, or archetypal overlap.

            Players should need discussion before they can
            confidently identify the Undercover.
            """

        case .hard:
            return """
            HARD — 0.70–1.00

            Extremely strong clue overlap without semantic equivalence.

            The concepts should be psychologically close but
            objectively different.

            Players should repeatedly think:

            "That clue works for both."

            Hard should feel clever, not confusing.
            """
        }
    }

    private func topicPrompt(
        _ topic: String
    ) -> String {

        let trimmed = topic
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return """
            TOPIC:
            No specific topic.

            Use broadly recognizable concepts from everyday life,
            entertainment, culture, technology, sports, food,
            places, people, brands, and common experiences.

            Prefer culturally accessible concepts.
            """
        }

        return """
        TOPIC:
        \(trimmed)

        Interpret this as a broad semantic universe.

        The concepts should clearly belong to or strongly connect
        with this universe.

        You may explore different aspects of the topic rather than
        staying inside one narrow category.
        """
    }

    private func exclusionPrompt(
        _ excluding: Set<String>
    ) -> String {

        guard !excluding.isEmpty else {
            return ""
        }

        let words = excluding
            .sorted()
            .joined(separator: ", ")

        return """
        ALREADY USED CONCEPTS:

        \(words)

        Do NOT reuse any of these concepts.

        Also avoid obvious translations, alternate spellings,
        titles, aliases, or extremely direct equivalents.
        """
    }

    // MARK: - JSON Parsing

    private static func parseJSON(
        _ text: String,
        topic: String
    ) throws -> [WordPair] {

        var clean = text
            .replacingOccurrences(
                of: "```json",
                with: ""
            )
            .replacingOccurrences(
                of: "```",
                with: ""
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // Recover the JSON array if the model accidentally
        // added a small amount of surrounding text.
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

        struct Raw: Decodable {

            let civilian: [String: String]

            let undercover: [String: String]

            let similarity: Double?

            let relation: String?
        }

        let rawPairs: [Raw]

        do {

            rawPairs = try JSONDecoder().decode(
                [Raw].self,
                from: data
            )

        } catch {

            throw WordGeneratorError.parsingFailed(
                clean
            )
        }

        var seen = Set<String>()

        var pairs: [WordPair] = []

        let requiredLanguages = [
            "en",
            "fr",
            "es",
            "ar",
            "tn"
        ]

        for raw in rawPairs {

            let civilianEnglish = normalize(
                raw.civilian["en"]
            )

            let undercoverEnglish = normalize(
                raw.undercover["en"]
            )

            // Both concepts must exist.
            guard !civilianEnglish.isEmpty,
                  !undercoverEnglish.isEmpty
            else {
                continue
            }

            // Concepts cannot be identical.
            guard civilianEnglish != undercoverEnglish
            else {
                continue
            }

            // Do not allow any concept to appear twice
            // inside the same generated batch.
            guard !seen.contains(civilianEnglish),
                  !seen.contains(undercoverEnglish)
            else {
                continue
            }

            // Require every translation.
            let civilianComplete =
                hasAllLanguages(
                    raw.civilian,
                    languages: requiredLanguages
                )

            let undercoverComplete =
                hasAllLanguages(
                    raw.undercover,
                    languages: requiredLanguages
                )

            guard civilianComplete,
                  undercoverComplete
            else {
                continue
            }

            let civilian = LocalizedWord(
                values: raw.civilian
            )

            let undercover = LocalizedWord(
                values: raw.undercover
            )

            let pair = WordPair(
                civilian: civilian,
                undercover: undercover,
                topic: topic,
                similarity: raw.similarity
            )

            seen.insert(civilianEnglish)
            seen.insert(undercoverEnglish)

            pairs.append(pair)
        }

        guard !pairs.isEmpty else {
            throw WordGeneratorError.noPairsAvailable
        }

        return pairs
    }

    private static func hasAllLanguages(
        _ values: [String: String],
        languages: [String]
    ) -> Bool {

        languages.allSatisfy { language in

            guard let value = values[language]
            else {
                return false
            }

            return !value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        }
    }

    // MARK: - Normalization

    private static func normalize(
        _ value: String?
    ) -> String {

        guard let value else {
            return ""
        }

        return value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
            .folding(
                options: .diacriticInsensitive,
                locale: .current
            )
    }

    private func normalize(
        _ value: String
    ) -> String {

        value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
            .folding(
                options: .diacriticInsensitive,
                locale: .current
            )
    }
}
