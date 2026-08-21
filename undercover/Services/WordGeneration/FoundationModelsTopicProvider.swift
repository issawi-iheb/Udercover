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
                    to: "Generate exactly 30 premium game topics."
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

                guard !cleanedTopics.isEmpty else {
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
    You generate topics for a party game called "Undercover".

    A topic defines the universe from which word pairs will be generated.

    Generate exactly 30 diverse topics.

    TOPIC REQUIREMENTS:
    - Recognizable to average players.
    - Broad enough to contain many possible concepts.
    - Suitable for generating interesting Undercover word pairs.
    - Diverse across entertainment, culture, everyday life, science, sports, places, and objects.
    - Avoid extremely niche subjects.
    - Avoid topics that are too narrow to generate many pairs.
    - Avoid duplicate or nearly identical topics.

    GOOD EXAMPLES:
    Movies
    Anime
    Football
    Technology
    Music
    Animals
    Food
    Countries
    Cities
    Brands
    Video Games
    Books
    History

    OUTPUT:
    Return ONLY a valid JSON array containing exactly 30 strings.

    Example:
    ["Movies", "Anime", "Football", "Technology", "Music", "Animals"]
    """

    // MARK: - JSON Cleaning

    private nonisolated static func cleanJSON(_ text: String) -> String {

        var clean = text
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
        "Cars"
    ]
}
