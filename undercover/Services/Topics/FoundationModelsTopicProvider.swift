//
//  FoundationModelsTopicProvider.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public actor FoundationModelsTopicProvider: TopicProvider {

    public nonisolated let source: TopicSource = .ai

    private var cachedTopics: [GameTopic]?

    public init() {}

    // MARK: - Public API

    public func topics() async -> [GameTopic] {

        if let cachedTopics, !cachedTopics.isEmpty {
            return cachedTopics
        }

        #if canImport(FoundationModels)

        guard #available(iOS 26.0, *) else {
            return Self.fallbackGameTopics()
        }

        let session = LanguageModelSession(
            instructions: Self.systemPrompt
        )

        do {
            let response = try await session.respond(
                to: """
                Generate 25 distinct topic categories for the party game Undercover.
                """
            )

            let topics = try Self.parseTopics(
                from: response.content
            )

            guard topics.count >= 20 else {
                print("""
                ⚠️ [FoundationModelsTopicProvider]
                Expected at least 20 unique topics, got \(topics.count)
                Using fallback topics.
                """)

                return Self.fallbackGameTopics()
            }

            let selectedTopics = Array(topics.prefix(20))

            let gameTopics = selectedTopics.map { topic in
                GameTopic(
                    id: Self.normalizeForID(topic),
                    name: topic,
                    source: .ai
                )
            }

            cachedTopics = gameTopics

            print("""
            🧠 [FoundationModelsTopicProvider]
            Generated \(gameTopics.count) AI topics:
            \(gameTopics.enumerated()
                .map {
                    "\($0.offset + 1). \($0.element.name)"
                }
                .joined(separator: "\n"))
            """)

            return gameTopics

        } catch {
            print(
                "[FoundationModelsTopicProvider] Generation failed:",
                error
            )

            print(
                "⚠️ [FoundationModelsTopicProvider] Using fallback topics."
            )

            return Self.fallbackGameTopics()
        }

        #else

        return Self.fallbackGameTopics()

        #endif
    }

    // MARK: - Parsing

    private nonisolated static func parseTopics(
        from response: String
    ) throws -> [String] {

        let json = cleanJSON(response)

        guard let data = json.data(using: .utf8) else {
            return []
        }

        let generatedTopics = try JSONDecoder().decode(
            [String].self,
            from: data
        )

        var uniqueTopics: [String] = []
        var seenIDs = Set<String>()

        for topic in generatedTopics {

            let name = topic.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !name.isEmpty else {
                continue
            }

            let id = normalizeForID(name)

            guard seenIDs.insert(id).inserted else {
                continue
            }

            uniqueTopics.append(name)
        }

        return uniqueTopics
    }

    // MARK: - System Prompt

    private nonisolated static let systemPrompt = """
    You generate topic categories for the party game "Undercover".

    UNDERCOVER MECHANIC

    Players receive secret words that are related but different.

    Example:

    Topic: Fruits
    Civilian: Apple
    Undercover: Pear

    The topic itself is NOT the pair.

    The topic defines a large universe from which the game can later
    generate many recognizable concepts and ambiguous word pairs.

    Generate 25 excellent topic categories.

    ────────────────────────────────────────
    WHAT MAKES A GOOD TOPIC
    ────────────────────────────────────────

    A good topic:

    - is immediately understandable
    - contains many recognizable concepts
    - can provide at least 20 different concepts
    - works well for similar-but-different word pairs
    - is fun for a social party game
    - is specific enough to feel like a real category
    - is broad enough to provide many possible pairs
    - is useful for players from different backgrounds

    GOOD EXAMPLES:

    - Anime
    - Superheroes
    - Car Brands
    - Video Games
    - Disney Characters
    - Horror Movies
    - European Cities
    - Famous Landmarks
    - Fast Food
    - Desserts
    - Dog Breeds
    - Musical Instruments
    - Sneakers
    - Smartphone Brands
    - Board Games
    - Supermarkets
    - Pop Stars
    - Countries
    - Football Players
    - Mythological Creatures

    ────────────────────────────────────────
    AVOID BAD TOPICS
    ────────────────────────────────────────

    Never generate topics that are too abstract or generic.

    BAD:

    - Things
    - Objects
    - Entertainment
    - Culture
    - Society
    - Technology
    - Science
    - History
    - Famous Things
    - Popular Things
    - Everyday Life

    These are too broad and do not define a useful word universe.

    ────────────────────────────────────────
    AVOID OVERLAPPING TOPICS
    ────────────────────────────────────────

    Do not generate multiple topics covering essentially the same universe.

    BAD:

    - Football
    - Football Players
    - Football Clubs

    BAD:

    - Cars
    - Car Brands
    - Sports Cars

    BAD:

    - Anime
    - Anime Characters
    - Anime Villains
    - Anime Shows

    Choose only ONE topic from a given universe.

    Every topic should add a genuinely different category to the final list.

    ────────────────────────────────────────
    DIVERSITY
    ────────────────────────────────────────

    Cover different types of recognizable universes.

    Include a balanced mixture of:

    - entertainment
    - food
    - brands
    - places
    - people
    - sports
    - animals
    - games
    - objects
    - fictional characters
    - lifestyle

    Do not fill the list with only movies, celebrities, or brands.

    ────────────────────────────────────────
    WORD-PAIR POTENTIAL
    ────────────────────────────────────────

    Prefer topics that naturally allow pairs of concepts that are:

    - related
    - recognizable
    - distinct enough to be different words
    - similar enough to create uncertainty
    - easy to describe with a single clue

    Examples:

    Desserts:
    - Brownie / Cookie
    - Waffle / Pancake
    - Donut / Bagel

    Dog Breeds:
    - Husky / Malamute
    - Beagle / Basset Hound
    - Labrador / Golden Retriever

    Famous Landmarks:
    - Eiffel Tower / Arc de Triomphe
    - Big Ben / London Eye
    - Colosseum / Pantheon

    Avoid categories where concepts would be too difficult to compare.

    ────────────────────────────────────────
    RECOGNIZABILITY
    ────────────────────────────────────────

    Prefer concepts that a typical player could recognize without
    specialist knowledge.

    Avoid:

    - obscure academic subjects
    - scientific classifications
    - niche professions
    - obscure historical events
    - highly specialized terminology
    - extremely regional references
    - topics requiring expert knowledge

    ────────────────────────────────────────
    TOPIC NAME
    ────────────────────────────────────────

    Topic names must be:

    - short
    - natural
    - recognizable
    - preferably 1–3 words

    Do not use generic prefixes such as:

    - Famous
    - Popular
    - Top
    - Best
    - Classic

    BAD:

    - Famous Movies
    - Popular Foods
    - Best Games

    GOOD:

    - Horror Movies
    - Desserts
    - Board Games

    ────────────────────────────────────────
    FINAL QUALITY CHECK
    ────────────────────────────────────────

    Before producing the final answer, verify every topic.

    For each topic ask:

    1. Is it immediately understandable?
    2. Does it contain at least 20 recognizable concepts?
    3. Can it generate interesting similar-but-different word pairs?
    4. Is it fun for a party game?
    5. Is it sufficiently different from the other topics?
    6. Is it neither too broad nor too niche?

    If a topic fails any check, replace it.

    ────────────────────────────────────────
    OUTPUT FORMAT
    ────────────────────────────────────────

    Return ONLY a JSON array containing 25 topic names.

    No explanation.
    No markdown.
    No numbering.
    No additional text.

    Example:

    [
        "Anime",
        "Car Brands",
        "Superheroes",
        "European Cities",
        "Fast Food",
        "Video Games",
        "Pop Stars",
        "Board Games",
        "Dog Breeds",
        "Desserts",
        "Sneakers",
        "Disney Characters",
        "Musical Instruments",
        "Famous Landmarks",
        "Smartphone Brands",
        "Horror Movies",
        "Football Players",
        "Countries",
        "Supermarkets",
        "Mythological Creatures",
        "Cocktails",
        "Comic Book Heroes",
        "Breakfast Foods",
        "Theme Parks",
        "Household Appliances"
    ]
    """

    // MARK: - JSON Cleaning

    private nonisolated static func cleanJSON(
        _ text: String
    ) -> String {

        let clean = text
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

        guard
            let start = clean.firstIndex(of: "["),
            let end = clean.lastIndex(of: "]"),
            start <= end
        else {
            return clean
        }

        return String(clean[start...end])
    }

    // MARK: - Fallback

    private nonisolated static let fallbackTopics = [
        "Movies",
        "Anime",
        "Television",
        "Football",
        "Basketball",
        "Technology",
        "Music",
        "Animals",
        "Food",
        "Countries",
        "Cities",
        "Brands",
        "Video Games",
        "Books",
        "History",
        "Celebrities",
        "Sports Teams",
        "Mythology",
        "Fashion",
        "Architecture"
    ]

    private nonisolated static func fallbackGameTopics()
        -> [GameTopic]
    {
        fallbackTopics.map { topic in
            GameTopic(
                id: normalizeForID(topic),
                name: topic,
                source: .ai
            )
        }
    }

    // MARK: - ID Normalization

    private nonisolated static func normalizeForID(
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
            .replacingOccurrences(
                of: " ",
                with: "-"
            )
    }
}
