//
//  FoundationModelsWordGenerator.swift
//  undercoverApp
//
//  Uses Apple's on-device FoundationModels (iOS 26+, Apple Intelligence).
//  Optimized for token efficiency and lightweight Swift-side filtering.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public actor FoundationModelsWordGenerator: WordGeneratorProtocol {
    
    public let generatorName = "Apple Intelligence (On-Device)"
    
    private var cache: [String: [WordPair]] = [:]
    
    // MARK: - System Prompt
    
    private nonisolated static let baseSystemPrompt = """
    You generate word pairs for "Undercover", a social-deduction game.
    
    GAMEPLAY GOAL:
    The game is fun when players hesitate over their clues.
    
    Generate two DIFFERENT concepts where at least 3 natural clues can honestly describe BOTH.
    
    Imagine a player has concept A and wants to give a clue that:
    1. proves they know A
    2. but could ALSO honestly describe concept B
    
    A strong pair creates this hesitation multiple times.
    
    EXAMPLE:
    Batman / Sherlock Holmes
    
    Possible shared clues:
    - detective
    - mysterious
    - intelligent
    - iconic
    - dark
    - crime-fighting
    
    Both concepts are distinct, but their clue spaces overlap.
    
    THE CLUE TEST — MOST IMPORTANT:
    Before accepting a pair, mentally test at least 3 realistic clues.
    
    For every clue ask:
    "Would a normal player honestly use this clue for BOTH concepts?"
    
    If 3+ clues naturally fit both → ACCEPT.
    
    If the overlap depends on trivia, technical knowledge,
    obscure fandom knowledge, or a forced interpretation → REJECT.
    
    Meaningful shared clues can come from:
    - identity
    - personality
    - role
    - appearance
    - behavior
    - reputation
    - symbolism
    - cultural meaning
    - emotional association
    - environment
    - archetype
    
    DO NOT COUNT THESE AS MEANINGFUL OVERLAP:
    - same actor
    - same voice actor
    - same creator
    - same author
    - same director
    - same studio
    - same company
    - same release year
    - same country
    - same production team
    - same genre alone
    - both belonging to a broad category
    - obscure trivia
    
    IDENTITY CONTAINMENT RULE:
    The two concepts must be genuinely separate entities.
    
    NEVER pair a concept with something that is part of it.
    
    REJECT:
    - Batman / Bruce Wayne
    - Game of Thrones / Jon Snow
    - Apple / iPhone
    - Sherlock Holmes / BBC Sherlock
    - Star Wars / Darth Vader
    - Pokémon / Pikachu
    - Harry Potter / Hogwarts
    - Marvel / Spider-Man
    
    ALSO REJECT:
    - original / sequel
    - original / remake
    - series / episode
    - franchise / spin-off
    - franchise / character
    - universe / character
    - book / character
    - movie / character
    - game / character
    - category / individual member
    - parent brand / simple product instance
    
    GOOD:
    - Batman / Sherlock Holmes
    - Sherlock Holmes / Hercule Poirot
    - Game of Thrones / The Witcher
    - Apple / Microsoft
    - Coca-Cola / Pepsi
    
    CONCEPT LEVEL:
    Both concepts should normally exist at the same conceptual level.
    
    VALID:
    - character ↔ character
    - movie ↔ movie
    - series ↔ series
    - franchise ↔ franchise
    - brand ↔ brand
    - city ↔ city
    - country ↔ country
    - animal ↔ animal
    - food ↔ food
    - athlete ↔ athlete
    - team ↔ team
    - product ↔ product
    
    INVALID:
    - series ↔ character
    - franchise ↔ character
    - brand ↔ product
    - movie ↔ character
    - universe ↔ character
    - category ↔ individual member
    - book ↔ character
    - game ↔ character
    
    If a strong pair cannot be found at the same conceptual level,
    REJECT the candidate instead of relaxing this rule.
    
    TOPIC:
    Both concepts must directly belong to the requested topic.
    
    Interpret the topic according to its natural meaning.
    
    Examples:
    
    Anime:
    - anime characters
    - anime series
    - anime films
    
    Movies:
    - films
    - movie characters only if the topic explicitly allows characters
    
    Brands:
    - brands
    
    Football:
    - football players
    - football teams
    - football competitions
    - football concepts
    
    Food:
    - foods
    - dishes
    - ingredients
    
    Cars:
    - car brands
    - car models
    
    Mythology:
    - gods
    - heroes
    - creatures
    - mythological figures
    
    Do NOT drift into games, merchandise, actors, creators,
    companies, locations, or adjacent concepts unless they clearly
    belong directly to the requested topic.
    
    RELATIONSHIP:
    The relationship should explain WHY the pair creates useful
    overlapping clues.
    
    Good relationship types include:
    - shared archetype
    - similar role
    - iconic rivals
    - competing brands
    - similar personality
    - symbolic parallels
    - similar cultural image
    - similar emotional experience
    - similar environment
    - contrasting versions of the same archetype
    - shared reputation
    - shared behavior
    - shared symbolism
    
    The relationship must be useful for gameplay.
    
    Do NOT use relationships based only on:
    - same actor
    - same creator
    - same studio
    - same release year
    - same franchise
    - obscure trivia
    - technical metadata
    
    DIVERSITY:
    Generate 10 different pairs.
    
    Avoid repeatedly using the same concept.
    
    Avoid repeatedly using the same relationship pattern.
    
    Vary the clue space and relationship type across the 10 pairs.
    
    Do not generate ten pairs that are all essentially the same relationship.
    
    RECOGNIZABILITY:
    Prefer concepts known by average players.
    
    Avoid:
    - obscure characters
    - minor fictional characters
    - niche references
    - technical terminology
    - deep fandom knowledge
    - extremely regional references
    
    DIFFICULTY:
    
    easy:
    Obvious shared clues.
    Players quickly understand why both concepts fit.
    
    medium:
    Several natural shared clues.
    Players need some discussion to decide which word is theirs.
    
    hard:
    Subtle psychological, symbolic, cultural, emotional,
    or archetypal overlap.
    
    HARD does NOT mean:
    - obscure
    - extremely niche
    - synonyms
    - almost identical concepts
    - same franchise
    - same entity
    - direct translations
    
    HARD means:
    The concepts are clearly different, but their deeper
    characteristics create unexpected clue overlap.
    
    TRANSLATION:
    Generate the concepts in English first.
    
    Output exactly these five language keys:
    "en", "fr", "es", "ar", "tn"
    
    fr = French
    es = Spanish
    ar = Modern Standard Arabic
    tn = Tunisian Arabic / Derja
    
    All five values must refer to the EXACT SAME CONCEPT.
    
    Use natural translations.
    
    Preserve famous names and brands when they normally remain unchanged.
    
    Do not translate a proper name into a different entity.
    
    SIMILARITY:
    Estimate GAMEPLAY clue overlap, not dictionary similarity.
    
    Value must be between 0.00 and 1.00.
    
    easy: 0.40–0.54
    medium: 0.55–0.69
    hard: 0.70–1.00
    
    This is only a gameplay estimate.
    
    OUTPUT:
    Return exactly 10 objects.
    
    Return valid JSON only.
    
    No markdown.
    No code fences.
    No explanation.
    No comments.
    No extra text.
    
    REQUIRED FORMAT:
    
    [
      {
        "civilian": {
          "en": "Batman",
          "fr": "Batman",
          "es": "Batman",
          "ar": "باتمان",
          "tn": "Batman"
        },
        "undercover": {
          "en": "Sherlock Holmes",
          "fr": "Sherlock Holmes",
          "es": "Sherlock Holmes",
          "ar": "شيرلوك هولمز",
          "tn": "Sherlock Holmes"
        },
        "similarity": 0.65,
        "relation": "shared detective archetype"
      }
    ]
    """
    
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
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let key = "\(language.rawValue)|\(normalizedTopic)|\(difficulty.rawValue)"
        
        let normalizedExcluded = Set(
            excluding.map {
                Self.normalize($0)
            }
        )
        
        func filtered(_ pairs: [WordPair]) -> [WordPair] {
            pairs.filter { pair in
                
                let civilianKey = Self.normalize(
                    pair.civilian.values["en"]
                )
                
                let undercoverKey = Self.normalize(
                    pair.undercover.values["en"]
                )
                
                return !normalizedExcluded.contains(civilianKey)
                && !normalizedExcluded.contains(undercoverKey)
            }
        }
        
        // ---------------------------------------------------------
        // 1. Try existing cache
        // ---------------------------------------------------------
        
        var available = filtered(
            cache[key] ?? []
        )
        
        if let pair = available.randomElement() {
            return pair
        }
        
        // ---------------------------------------------------------
        // 2. Generate with one retry
        // ---------------------------------------------------------
        
        var attempts = 0
        
        while attempts < 2 {
            
            attempts += 1
            
            do {
                
                let fresh = try await fetchViaLLM(
                    topic: normalizedTopic,
                    language: language,
                    difficulty: difficulty,
                    excluding: excluding
                )
                
                cache[key, default: []].append(
                    contentsOf: fresh
                )
                
                available = filtered(fresh)
                
                if let pair = available.randomElement() {
                    return pair
                }
                
            } catch {
                
                // Retry once if the model produced invalid JSON
                // or no valid pairs.
                if attempts >= 2 {
                    throw error
                }
            }
        }
        
        throw WordGeneratorError.noPairsAvailable
    }
    
    // MARK: - LLM Query
    
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
        
        let session = LanguageModelSession(
            instructions: Self.baseSystemPrompt
        )
        
        let topicValue = topic.isEmpty
        ? "General Everyday Concepts"
        : topic
        
        let exclusionText: String
        
        if excluding.isEmpty {
            exclusionText = ""
        } else {
            exclusionText = """
            EXCLUDE THESE CONCEPTS:
            \(excluding.sorted().joined(separator: ", "))
            
            Do not use any of these concepts in either side of a pair.
            """
        }
        
        let prompt = """
        TOPIC: \(topicValue)
        
        DIFFICULTY: \(difficulty.rawValue)
        
        \(exclusionText)
        
        Generate exactly 10 pairs.
        
        Remember:
        - Every pair must create real clue ambiguity.
        - Every pair must contain two distinct concepts.
        - Never use identity containment.
        - Never mix incompatible conceptual levels.
        - Stay directly within the topic.
        - Use different relationship types.
        - Return JSON only.
        """
        
        let response = try await session.respond(
            to: prompt
        )
        
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
        
        // ---------------------------------------------------------
        // Extract JSON array if model added surrounding text.
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
            throw WordGeneratorError.parsingFailed(clean)
        }
        
        // ---------------------------------------------------------
        // Flexible JSON model.
        //
        // Accepts both:
        //
        // "civilian": "Batman"
        //
        // and:
        //
        // "civilian": {
        //     "en": "Batman",
        //     ...
        // }
        //
        // The second format is preferred.
        // ---------------------------------------------------------
        
        struct RawPair: Decodable {
            
            let civilian: FlexibleValue
            let undercover: FlexibleValue
            let similarity: Double?
            let relation: String?
            
            enum FlexibleValue: Decodable {
                
                case string(String)
                case dictionary([String: String])
                
                init(from decoder: Decoder) throws {
                    
                    let container =
                    try decoder.singleValueContainer()
                    
                    if let dictionary = try? container.decode(
                        [String: String].self
                    ) {
                        self = .dictionary(dictionary)
                        return
                    }
                    
                    if let string = try? container.decode(
                        String.self
                    ) {
                        self = .string(string)
                        return
                    }
                    
                    throw DecodingError.typeMismatch(
                        FlexibleValue.self,
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription:
                                "Expected String or [String: String]"
                        )
                    )
                }
                
                func toDictionary() -> [String: String] {
                    
                    switch self {
                            
                        case .dictionary(let dictionary):
                            return dictionary
                            
                        case .string(let value):
                            
                            // Legacy/simple response.
                            //
                            // We duplicate the value across languages
                            // so the pair can still be parsed.
                            //
                            // This is intentionally accepted only as
                            // a parser fallback.
                            
                            return [
                                "en": value,
                                "fr": value,
                                "es": value,
                                "ar": value,
                                "tn": value
                            ]
                    }
                }
            }
        }
        
        guard let rawPairs = try? JSONDecoder().decode(
            [RawPair].self,
            from: data
        ) else {
            
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
        
        // ---------------------------------------------------------
        // Validate each candidate.
        // ---------------------------------------------------------
        
        for raw in rawPairs {
            
            let civilianValues =
            raw.civilian.toDictionary()
            
            let undercoverValues =
            raw.undercover.toDictionary()
            
            let civilianEN = normalize(
                civilianValues["en"]
            )
            
            let undercoverEN = normalize(
                undercoverValues["en"]
            )
            
            // -----------------------------------------------------
            // 1. Non-empty
            // -----------------------------------------------------
            
            guard !civilianEN.isEmpty,
                  !undercoverEN.isEmpty else {
                continue
            }
            
            // -----------------------------------------------------
            // 2. Exact same concept
            // -----------------------------------------------------
            
            guard civilianEN != undercoverEN else {
                continue
            }
            
            // -----------------------------------------------------
            // 3. Obvious token containment
            //
            // Example:
            // "Star Trek"
            // "Star Trek Voyager"
            //
            // "Naruto"
            // "Naruto Shippuden"
            // -----------------------------------------------------
            
            let civilianTokens = Set(
                civilianEN.components(
                    separatedBy: .whitespaces
                )
            )
            
            let undercoverTokens = Set(
                undercoverEN.components(
                    separatedBy: .whitespaces
                )
            )
            
            if civilianTokens.isSubset(
                of: undercoverTokens
            ) ||
                undercoverTokens.isSubset(
                    of: civilianTokens
                ) {
                continue
            }
            
            // -----------------------------------------------------
            // 4. Deduplicate concepts inside this batch.
            // -----------------------------------------------------
            
            guard !seen.contains(civilianEN),
                  !seen.contains(undercoverEN) else {
                continue
            }
            
            // -----------------------------------------------------
            // 5. Translation validation
            // -----------------------------------------------------
            
            var validTranslations = true
            
            for language in requiredLanguages {
                
                guard
                    let civilianValue =
                        civilianValues[language]?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                    
                        let undercoverValue =
                        undercoverValues[language]?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                    
                        !civilianValue.isEmpty,
                    !undercoverValue.isEmpty
                        
                else {
                    validTranslations = false
                    break
                }
            }
            
            guard validTranslations else {
                continue
            }
            
            // -----------------------------------------------------
            // 6. Reject identical translations
            //
            // This catches cases where two concepts collapse
            // into the same translated value.
            // -----------------------------------------------------
            
            var translationCollision = false
            
            for language in requiredLanguages {
                
                let civilianValue = normalize(
                    civilianValues[language]
                )
                
                let undercoverValue = normalize(
                    undercoverValues[language]
                )
                
                if !civilianValue.isEmpty,
                   civilianValue == undercoverValue {
                    
                    translationCollision = true
                    break
                }
            }
            
            guard !translationCollision else {
                continue
            }
            
            // -----------------------------------------------------
            // 7. Similarity
            // -----------------------------------------------------
            
            let similarity: Double?
            
            if let value = raw.similarity,
               value >= 0.0,
               value <= 1.0 {
                
                similarity = value
                
            } else {
                
                similarity = nil
            }
            
            // -----------------------------------------------------
            // 8. Build domain objects
            // -----------------------------------------------------
            
            let civilian = LocalizedWord(
                values: civilianValues
            )
            
            let undercover = LocalizedWord(
                values: undercoverValues
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
        // At least one valid pair must survive.
        // ---------------------------------------------------------
        
        guard !pairs.isEmpty else {
            throw WordGeneratorError.noPairsAvailable
        }
        
        return pairs
    }
    
    // MARK: - Normalization
    
    private nonisolated static func normalize(
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
}
