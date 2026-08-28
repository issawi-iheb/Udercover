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

    public init() {}

    private var cachedTopics: [String]?

    // MARK: - Public API

    public func topics() async -> [String] {

        // Return cached topics if already generated.
        if let cachedTopics, !cachedTopics.isEmpty {
            return cachedTopics
        }

        #if canImport(FoundationModels)

        if #available(iOS 26.0, *) {

            let session = LanguageModelSession(
                instructions: Self.systemPrompt
            )

            do {
                let response = try await session.respond(
                    to: "Generate 20 distinct, high-quality topics for Undercover."
                )

                let json = Self.cleanJSON(response.content)

                guard let data = json.data(using: .utf8) else {
                    return Self.fallbackTopics
                }

                let generatedTopics = try JSONDecoder().decode(
                    [String].self,
                    from: data
                )

                let cleanedTopics = generatedTopics
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
                    .filter { !$0.isEmpty }
                print("""
                🧠 [FoundationModelsTopicProvider]
                Generated topics:
                \(cleanedTopics.enumerated()
                    .map { "\($0.offset + 1). \($0.element)" }
                    .joined(separator: "\n"))
                """)
                guard cleanedTopics.count == 20 else {
                    print("""
                    ⚠️ [FoundationModelsTopicProvider]
                    Expected exactly 20 topics, got \(cleanedTopics.count)
                    """)

                    return Self.fallbackTopics
                }

                self.cachedTopics = cleanedTopics

                return cleanedTopics

            } catch {
                print(
                    "[FoundationModelsTopicProvider] Generation failed:",
                    error
                )

                return Self.fallbackTopics
            }
        }

        #endif

        return Self.fallbackTopics
    }

    // MARK: - System Prompt

    private nonisolated static let systemPrompt = """
    You generate topics for the party game "Undercover".

    A good topic is a recognizable universe that contains many possible concepts for ambiguous word pairs.

    RULES:
    1. Generate exactly 20 distinct topics.
    2. Each topic must represent a completely different domain.
    3. Never use generic prefixes like "Famous", "Top", or "Popular".
    4. Avoid overlapping or near-identical topics (e.g., do not generate both "Fast Food" and "Fast Food Chains").

    GOOD TOPIC TYPES:
    - Media: Anime, Movies, Video Games, Superheroes, Sitcoms
    - People: Football Players, Pop Stars, Historical Figures
    - Items: Fast Food, Car Brands, Board Games, Tropical Fruits
    - Geography: Countries, European Cities, Landmarks

    AVOID:
    - Abstract topics: Science, Culture, Psychology, Philosophy
    - Very broad topics: Things, Objects, Concepts
    - Multiple variations of the same universe.
    - Avoid starting topic names with generic prefixes like "Famous" or "Top".
    Instead of "Famous Cars", use "Cars" or "Sports Cars".
    Instead of "Famous Anime Characters", use "Anime Characters".

    BAD:
    Football
    Football Players
    Football Clubs
    Football Managers

    GOOD:
    Football Players
    Anime
    Car Brands
    European Cities
    Fast Food

    OUTPUT:
    Return ONLY a JSON array of exactly 20 strings.

    Example:
    [
    "Anime",
    "Fast Food",
    "Superheroes",
    "European Cities",
    "Video Games",
    "Car Brands"
    ]
    """

    // MARK: - JSON Cleaning

    private nonisolated static func cleanJSON(_ text: String) -> String {

        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
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
        "Architecture",
        "Cartoons",
        "Art",
        "Science",
        "Comedy",
        "Cars",
        "Professions",
        "Famous Places",
        "Board Games",
        "Internet Culture",
        "Space"
    ]
}
