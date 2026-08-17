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
    
    private func cleanJSON(_ text: String) -> String {

        var clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = clean.firstIndex(of: "["),
           let end = clean.lastIndex(of: "]") {

            clean = String(clean[start...end])
        }

        return clean
    }
    public func topics() async -> [String] {

        #if canImport(FoundationModels)

        if #available(iOS 26.0, *) {

            let session = LanguageModelSession(
                instructions: """
You generate game topics for a party game.

Return ONLY a JSON array.

No markdown.
No code block.
No explanation.

Example:

[
"Movies",
"Anime",
"Football",
"Technology"
]

Generate 20 popular topics.
"""
            )

            do {

                let response = try await session.respond(
                    to: "Generate 30 premium game topics."
                )

                let json = cleanJSON(response.content)

                guard let data = json.data(using: .utf8) else {
                    return []
                }

                return try JSONDecoder().decode(
                    [String].self,
                    from: data
                )

            } catch {
                print(error)
            }
        }

        #endif


        return [
            "Movies",
            "Anime",
            "Football",
            "Technology",
            "Music",
            "Animals"
        ]
    }
}
