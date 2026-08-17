//
//  FoundationModelsWordGenerator.swift
//  undercoverApp
//
//  Uses Apple's on-device FoundationModels (iOS 26+, Apple Intelligence).
//

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

    // MARK: - Protocol

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

        let excluded = Set(
            excluding.map {
                normalize($0)
            }
        )

        func filtered(_ pairs: [WordPair]) -> [WordPair] {
            pairs.filter { pair in
                let key = normalize(pair.trackingKey)

                return !excluded.contains(key)
            }
        }

        // First use already-generated pairs.
        var available = filtered(cache[key] ?? [])

        // Generate a new batch only when necessary.
        if available.isEmpty {

            let fresh = try await fetchViaLLM(
                topic: topic,
                language: language,
                difficulty: difficulty,
                excluding: excluding
            )

            cache[key, default: []].append(contentsOf: fresh)
            for pair in fresh {
                print(
                    pair.civilian.values["en"] ?? "",
                    "/",
                    pair.undercover.values["en"] ?? "",
                    pair.similarity ?? -1,
                    pair.difficulty
                )
            }
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

        let difficultyDescription: String

        switch difficulty {
        case .easy:
            difficultyDescription = """
            EASY:
            The two concepts should be clearly different.
            Players should usually identify the difference quickly.
            Similarity target: 0.40–0.54.
            """

        case .medium:
            difficultyDescription = """
            MEDIUM:
            The two concepts should belong to the same general context
            or category, but still be clearly different concepts.
            Players should need some discussion to distinguish them.
            Similarity target: 0.55–0.69.
            """

        case .hard:
            difficultyDescription = """
            HARD:
            The two concepts should be strongly related and deceptively close,
            but MUST still be genuinely different concepts.
            Players should have difficulty deciding which word they received.
            Similarity target: 0.70–1.00.
            """
        }

        let topicInstruction: String

        if topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            topicInstruction = """
            No specific topic was provided.

            Choose common, recognizable everyday concepts.
            Prefer things that most people know.
            """
        } else {
            topicInstruction = """
            TOPIC:
            \(topic)

            Keep the pair relevant to this topic.
            """
        }

        let excludedWords: String

        if excluding.isEmpty {
            excludedWords = ""
        } else {
            excludedWords = """
            
            WORDS ALREADY USED:
            \(excluding.sorted().joined(separator: ", "))

            Do NOT reuse any of these concepts.
            Avoid them even if they appear translated differently.
            """
        }

        let languageInstructions = """
        LANGUAGE REQUIREMENTS:

        Generate the same pair of concepts in ALL five languages.

        Required JSON keys:

        en = English
        fr = French
        es = Spanish
        ar = Modern Standard Arabic
        tn = Tunisian Arabic / Tunisian Derja

        IMPORTANT:

        "ar" and "tn" are NOT the same language.

        ARABIC (ar):
        - Use Modern Standard Arabic (الفصحى).
        - Use natural, commonly understood vocabulary.
        - Write using Arabic script.
        - Do not use Arabizi.

        TUNISIAN (tn):
        - Use natural Tunisian Arabic / Tunisian Derja.
        - Prefer expressions actually used by Tunisian speakers.
        - Write using Arabic script.
        - Do NOT simply copy the MSA translation.
        - Do NOT translate word-for-word from English.
        - Do NOT use Egyptian, Levantine, Moroccan or Gulf dialect.
        - Do NOT use Arabizi unless there is absolutely no natural Arabic-script equivalent.
        - When a Tunisian word is commonly used in everyday speech,
          prefer the Tunisian word over formal Arabic.

        Example distinction:

        English: "car"

        ar:
        "سيارة"

        tn:
        "كراهب"

        The Tunisian translation should sound like something
        a Tunisian person would naturally say in everyday conversation.

        IMPORTANT:
        All five translations must refer to EXACTLY the same concept.
        Do not create a different concept just to make a translation sound natural.
        """

        let instructions = """
        You are the AI game designer behind a premium social party game called "Undercover".

        Your mission is to create PERFECT undercover word pairs.

        This is NOT a dictionary game.

        This is a human psychology game.

        Players receive one of two concepts:

        - CIVILIAN word
        - UNDERCOVER word

        The two concepts must create this feeling:

        "These two things are connected... but they are definitely not the same."

        The best pairs create discussion, confusion and interesting clues.

        QUALITY > quantity.

        Generate exactly 10 premium pairs.

        Return ONLY valid JSON.

        No markdown.
        No explanations.
        No comments.

        FORMAT:

        [
         {
           "civilian":{
              "en":"",
              "fr":"",
              "es":"",
              "ar":"",
              "tn":""
           },
           "undercover":{
              "en":"",
              "fr":"",
              "es":"",
              "ar":"",
              "tn":""
           },
           "similarity":0.85,
           "relation":""
         }
        ]


        ================================
        CORE CREATIVE PRINCIPLE
        ================================

        Do not simply search inside the topic.

        Think like a human fan.

        Build connections using:

        - archetypes
        - emotions
        - cultural importance
        - visual identity
        - personality
        - role
        - symbolism
        - historical importance
        - audience association
        - gameplay clues


        The strongest pairs are NOT always from the same universe.

        A pair is good when players can describe both concepts using similar clues,
        but the concepts remain different.


        ================================
        EXAMPLE OF BAD AI THINKING
        ================================

        Topic: Anime

        BAD:

        Naruto / Sasuke
        Luffy / Blackbeard
        Goku / Vegeta

        Why?

        Because they are too obviously connected.

        Players immediately know the relationship.


        BETTER:

        Luffy / Zorro

        Because:

        - both are iconic adventure heroes
        - both use swords/pirate imagery
        - both have strong personalities
        - both create similar clues

        But they are different characters.


        ================================
        ARCHETYPE THINKING
        ================================

        For HARD difficulty, prioritize:

        1. SAME ARCHETYPE

        Examples:

        Zorro / Luffy

        Batman / Sherlock Holmes

        Iron Man / Tony Stark style characters

        Messi / Michael Jordan

        Apple / Tesla


        2. SAME CULTURAL LEVEL

        Examples:

        Christopher Nolan / Steven Spielberg

        Oppenheimer / Inception

        Avatar / Titanic


        3. SAME EMOTIONAL EXPERIENCE

        Examples:

        Interstellar / Arrival

        The Last of Us / Walking Dead


        4. SAME SYMBOLIC IMAGE

        Examples:

        Ferrari / Lamborghini

        Rolex / Cartier


        5. FAMOUS RIVALS

        Examples:

        Messi / Ronaldo

        Apple / Samsung

        Marvel / DC


        ================================
        TOPIC INTERPRETATION
        ================================

        Understand the topic, but do not stay trapped inside it.


        If topic is:

        "Movies"

        Think about:

        - famous films
        - directors
        - actors
        - characters
        - cinematic universes
        - cultural impact
        - movie archetypes


        "Anime"

        Think about:

        - characters
        - heroes
        - villains
        - personalities
        - fighting styles
        - worlds
        - iconic images


        "Technology"

        Think about:

        - companies
        - products
        - founders
        - innovations
        - competitors
        - cultural impact


        "Football"

        Think about:

        - players
        - clubs
        - legends
        - styles
        - rivalries
        - historical moments


        The topic is inspiration, not a prison.


        ================================
        DIFFICULTY SYSTEM
        ================================

        Difficulty:

        \(difficultyDescription)


        EASY:

        The concepts are related but clearly different.

        Examples:

        Coffee / Tea

        Dog / Cat

        Pizza / Burger


        Players should understand the difference quickly.


        MEDIUM:

        The concepts share a category, world, or cultural connection.

        Examples:

        Messi / Ronaldo

        Batman / Superman

        iPhone / Galaxy


        Players need discussion.


        HARD:

        The concepts should be psychologically close.

        The relationship should be indirect.

        Players should hesitate.

        Examples:

        Zorro / Luffy

        Inception / Oppenheimer

        Batman / Sherlock Holmes

        Apple / Tesla


        IMPORTANT:

        Hard does NOT mean synonyms.

        Hard means:

        "Two famous concepts that create similar mental associations."


        ================================
        NEVER GENERATE
        ================================

        Reject:

        - synonyms
        - translations
        - same object with another name
        - generic categories
        - parent-child relationships
        - subtype relationships
        - obvious dictionary pairs


        BAD:

        Car / Automobile

        Train / Rail

        Subway / Underground

        Taxi / Cab

        Movie / Film

        Phone / Smartphone

        Animal / Dog

        Fruit / Apple


        These are NOT fun.


        ================================
        GOOD PAIRS
        ================================

        GOOD:

        Zorro / Luffy

        Batman / Sherlock Holmes

        Oppenheimer / Inception

        Titanic / Avatar

        Messi / Ronaldo

        Apple / Tesla

        Ferrari / Lamborghini

        Coke / Pepsi

        Harry Potter / Lord of the Rings

        Iron Man / Captain America


        They create:

        - similar clues
        - different answers
        - discussion
        - uncertainty


        ================================
        LANGUAGE REQUIREMENTS
        ================================

        First create the perfect English concepts.

        Then translate them.

        All translations MUST represent exactly the same concept.

        Required languages:

        en:
        English

        fr:
        French

        es:
        Spanish

        ar:
        Modern Standard Arabic (الفصحى)

        tn:
        Tunisian Arabic / Derja


        ================================
        ARABIC RULES
        ================================

        Arabic (ar):

        - Use Modern Standard Arabic.
        - Use Arabic script.
        - No Arabizi.
        - No dialect.


        Tunisian (tn):

        - Use real Tunisian everyday speech.
        - Prefer Tunisian vocabulary.
        - Do not copy MSA.
        - Do not use Egyptian, Moroccan, Levantine or Gulf Arabic.
        - Do not translate literally if Tunisians naturally use another word.


        Example:

        English:
        car


        Arabic:
        سيارة


        Tunisian:
        كرهبة


        The Tunisian version must sound natural to a Tunisian player.


        ================================
        EXCLUDED WORDS
        ================================

        Avoid generating:

        \(excluding)


        Do not reuse these concepts.

        Avoid translated versions of these concepts too.


        ================================
        FINAL QUALITY CHECK
        ================================

        Before returning JSON, verify every pair:

        1. Are both concepts famous or recognizable?
        2. Are they different concepts?
        3. Can players give creative clues?
        4. Are they connected psychologically?
        5. Would humans debate the answer?
        6. Is the relationship interesting?
        7. Are translations correct?
        8. Is Tunisian Arabic natural?


        Delete any boring pair.

        Return only premium Undercover pairs.
        """

        let session = LanguageModelSession(
            instructions: instructions
        )

        let response = try await session.respond(
            to: """
            \(topicInstruction)

            Difficulty:
            \(difficultyDescription)

            Generate exactly 10 high-quality pairs now.
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

    // MARK: - JSON Parsing

    private static func parseJSON(
        _ text: String,
        topic: String
    ) throws -> [WordPair] {

        var clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // Extract the JSON array if the model added anything around it.
        if let start = clean.firstIndex(of: "["),
           let end = clean.lastIndex(of: "]"),
           start < end {

            clean = String(
                clean[start...end]
            )
        }

        guard let data = clean.data(using: .utf8) else {
            throw WordGeneratorError.parsingFailed(clean)
        }

        struct Raw: Decodable {
            let civilian: [String: String]
            let undercover: [String: String]
            let similarity: Double?
        }

        let rawPairs = try JSONDecoder().decode(
            [Raw].self,
            from: data
        )

        var seen = Set<String>()
        var pairs: [WordPair] = []

        for raw in rawPairs {

            let civilian = LocalizedWord(
                values: raw.civilian
            )

            let undercover = LocalizedWord(
                values: raw.undercover
            )

            let civilianEnglish = normalize(
                raw.civilian["en"]
            )

            let undercoverEnglish = normalize(
                raw.undercover["en"]
            )

            // Both concepts must exist.
            guard !civilianEnglish.isEmpty,
                  !undercoverEnglish.isEmpty else {
                continue
            }

            // Cannot be exactly the same concept.
            guard civilianEnglish != undercoverEnglish else {
                continue
            }

            // Every English concept must be unique.
            guard !seen.contains(civilianEnglish),
                  !seen.contains(undercoverEnglish) else {
                continue
            }

            // Require all five translations.
            let requiredLanguages = [
                "en",
                "fr",
                "es",
                "ar",
                "tn"
            ]

            let hasAllTranslations = requiredLanguages.allSatisfy {
                guard let value = raw.civilian[$0] else {
                    return false
                }

                return !value
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            }
            &&
            requiredLanguages.allSatisfy {
                guard let value = raw.undercover[$0] else {
                    return false
                }

                return !value
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            }

            guard hasAllTranslations else {
                continue
            }

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
