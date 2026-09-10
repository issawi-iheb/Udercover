//
//  FoundationModelsWordGeneratorTests.swift
//  undercoverTests
//
//  Created by Iheb on 09/09/2026.
//

import Testing
@testable import undercover

struct FoundationModelsWordGeneratorTests {

    // MARK: - Fixtures

    private func makePair(
        civilian: String,
        undercover: String,
        topic: String = "animals",
        language: AppLanguage = .english,
        similarity: Double = 0.62
    ) -> WordPair {
        WordPair(
            civilian: LocalizedWord(
                values: [
                    language.rawValue: civilian
                ]
            ),
            undercover: LocalizedWord(
                values: [
                    language.rawValue: undercover
                ]
            ),
            topic: topic,
            similarity: similarity
        )
    }

    private func validSimilarity(
        for difficulty: PairDifficulty
    ) -> Double {
        difficulty.scoreRange.lowerBound
    }

    private func validJSON(
        civilian: String = "cat",
        undercover: String = "dog",
        similarity: Double = 0.62
    ) -> String {
        """
        [
          {
            "civilian": "\(civilian)",
            "undercover": "\(undercover)",
            "similarity": \(similarity)
          }
        ]
        """
    }

    // MARK: - Metadata

    @Test
    func generator_hasExpectedMetadata() async {

        let generator = FoundationModelsWordGenerator()

        let name = await generator.generatorName
        let kind = await generator.kind

        #expect(
            name == "Apple Intelligence (On-Device)"
        )

        await MainActor.run {
            #expect(kind == .background)
        }
    }

    // MARK: - Candidate Selection

    @Test
    func firstAvailablePair_returnsFirstValidPair() async {

        let generator = FoundationModelsWordGenerator()

        let first = makePair(
            civilian: "Cat",
            undercover: "Dog"
        )

        let second = makePair(
            civilian: "Lion",
            undercover: "Tiger"
        )

        let result = generator.firstAvailablePair(
            from: [first, second],
            language: .english,
            excluding: []
        )
        await MainActor.run {
            #expect(result == first)
        }
    }

    @Test
    func firstAvailablePair_skipsPairWithEmptyCivilian() async {

        let generator = FoundationModelsWordGenerator()

        let invalid = makePair(
            civilian: "",
            undercover: "Dog"
        )

        let valid = makePair(
            civilian: "Cat",
            undercover: "Dog"
        )

        let result = generator.firstAvailablePair(
            from: [invalid, valid],
            language: .english,
            excluding: []
        )

        await MainActor.run {
            #expect(result == valid)
        }
    }

    @Test
    func firstAvailablePair_skipsPairWithEmptyUndercover() async {

        let generator = FoundationModelsWordGenerator()

        let invalid = makePair(
            civilian: "Cat",
            undercover: ""
        )

        let valid = makePair(
            civilian: "Lion",
            undercover: "Tiger"
        )

        let result = generator.firstAvailablePair(
            from: [invalid, valid],
            language: .english,
            excluding: []
        )
        await MainActor.run {
            #expect(result == valid)
        }
        
    }

    @Test
    func firstAvailablePair_skipsExcludedCivilian() async {

        let generator = FoundationModelsWordGenerator()

        let excluded = makePair(
            civilian: "Cat",
            undercover: "Dog"
        )

        let valid = makePair(
            civilian: "Lion",
            undercover: "Tiger"
        )

        let result = generator.firstAvailablePair(
            from: [excluded, valid],
            language: .english,
            excluding: ["cat"]
        )
    await MainActor.run {
    #expect(result == valid)
        }
        
    }

    @Test
    func firstAvailablePair_skipsExcludedUndercover() async {

        let generator = FoundationModelsWordGenerator()

        let excluded = makePair(
            civilian: "Cat",
            undercover: "Dog"
        )

        let valid = makePair(
            civilian: "Lion",
            undercover: "Tiger"
        )

        let result = generator.firstAvailablePair(
            from: [excluded, valid],
            language: .english,
            excluding: ["dog"]
        )
        await MainActor.run {
            #expect(result == valid)
        }
    }

    @Test
    func firstAvailablePair_returnsNil_whenAllPairsConflict() {

        let generator = FoundationModelsWordGenerator()

        let first = makePair(
            civilian: "Cat",
            undercover: "Dog"
        )

        let second = makePair(
            civilian: "Lion",
            undercover: "Tiger"
        )

        let result = generator.firstAvailablePair(
            from: [first, second],
            language: .english,
            excluding: [
                "cat",
                "dog",
                "lion",
                "tiger"
            ]
        )

        #expect(result == nil)
    }

    // MARK: - Exclusion Matching

    @Test
    func matchesExcluded_returnsTrue_forExactMatch() {

        #expect(
            FoundationModelsWordGenerator.matchesExcluded(
                "cat",
                excluded: ["cat"]
            )
        )
    }

    @Test
    func matchesExcluded_returnsFalse_forDifferentConcepts() {

        #expect(
            !FoundationModelsWordGenerator.matchesExcluded(
                "cat",
                excluded: ["dog"]
            )
        )
    }

    @Test
    func matchesExcluded_detectsSubsetRelationship() {

        #expect(
            FoundationModelsWordGenerator.matchesExcluded(
                "new york",
                excluded: ["new york city"]
            )
        )

        #expect(
            FoundationModelsWordGenerator.matchesExcluded(
                "new york city",
                excluded: ["new york"]
            )
        )
    }

    @Test
    func matchesExcluded_handlesEmptyCandidate() {

        #expect(
            FoundationModelsWordGenerator.matchesExcluded(
                "",
                excluded: []
            )
        )
    }

    @Test
    func matchesExcluded_doesNotMatchUnrelatedMultiWordConcepts() {

        #expect(
            !FoundationModelsWordGenerator.matchesExcluded(
                "new york",
                excluded: ["new jersey"]
            )
        )
    }

    // MARK: - JSON Parsing

    @Test
    func parseAndValidateJSON_parsesValidResponse() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = validJSON(
            civilian: "cat",
            undercover: "dog",
            similarity: similarity
        )

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 1)
        #expect(
            result[0].civilian.localized(for: .english)
                == "cat"
        )
        #expect(
            result[0].undercover.localized(for: .english)
                == "dog"
        )
        #expect(result[0].topic == "animals")
        #expect(result[0].similarity == similarity)
    }

    @Test
    func parseAndValidateJSON_parsesMarkdownCodeFence() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = """
        ```json
        [
          {
            "civilian": "cat",
            "undercover": "dog",
            "similarity": \(similarity)
          }
        ]
        ```
        """

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 1)
    }

    @Test
    func parseAndValidateJSON_parsesJSONSurroundedByText() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let text = """
        Here are the generated pairs:

        [
          {
            "civilian": "cat",
            "undercover": "dog",
            "similarity": \(similarity)
          }
        ]

        Hope these work!
        """

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                text,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 1)
    }

    @Test
    func parseAndValidateJSON_acceptsSimilarityAsString() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = """
        [
          {
            "civilian": "cat",
            "undercover": "dog",
            "similarity": "\(similarity)"
          }
        ]
        """

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 1)
        #expect(result[0].similarity == similarity)
    }

    @Test
    func parseAndValidateJSON_throwsParsingFailed_forMalformedJSON() {

        let json = """
        [
          {
            "civilian": "cat",
            "undercover":
        """

        let difficulty = PairDifficulty.allCases.first!

        #expect(
            throws: WordGeneratorError.parsingFailed(json)
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    @Test
    func parseAndValidateJSON_throwsNoPairsAvailable_whenResponseIsEmpty() {

        let json = "[]"

        let difficulty = PairDifficulty.allCases.first!

        #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    // MARK: - Invalid Pairs

    @Test
    func parseAndValidateJSON_skipsEmptyCivilian() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = """
        [
          {
            "civilian": "",
            "undercover": "dog",
            "similarity": \(similarity)
          },
          {
            "civilian": "cat",
            "undercover": "dog",
            "similarity": \(similarity)
          }
        ]
        """

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 1)
        #expect(
            result[0].civilian.localized(for: .english)
                == "cat"
        )
    }

    @Test
    func parseAndValidateJSON_skipsEmptyUndercover() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = """
        [
          {
            "civilian": "cat",
            "undercover": "",
            "similarity": \(similarity)
          },
          {
            "civilian": "lion",
            "undercover": "tiger",
            "similarity": \(similarity)
          }
        ]
        """

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 1)
        #expect(
            result[0].civilian.localized(for: .english)
                == "lion"
        )
    }

    @Test
    func parseAndValidateJSON_skipsIdenticalConcepts() {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = validJSON(
            civilian: "cat",
            undercover: "cat",
            similarity: similarity
        )

        #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    @Test
    func parseAndValidateJSON_skipsSubsetConcepts() {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = validJSON(
            civilian: "new york",
            undercover: "new york city",
            similarity: similarity
        )

        #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "places",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    // MARK: - Similarity Validation

    @Test
    func parseAndValidateJSON_skipsMissingSimilarity() {

        let difficulty = PairDifficulty.allCases.first!

        let json = """
        [
          {
            "civilian": "cat",
            "undercover": "dog"
          }
        ]
        """

        #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    @Test
    func parseAndValidateJSON_skipsSimilarityBelowZero() {

        let difficulty = PairDifficulty.allCases.first!

        let json = validJSON(
            similarity: -0.1
        )

        #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    @Test
    func parseAndValidateJSON_skipsSimilarityAboveOne() {

        let difficulty = PairDifficulty.allCases.first!

        let json = validJSON(
            similarity: 1.1
        )

        #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    @Test
    func parseAndValidateJSON_skipsSimilarityOutsideDifficultyRange() {

        let difficulty = PairDifficulty.allCases.first!

        let range = difficulty.scoreRange

        let outsideRange: Double

        if range.lowerBound > 0 {
            outsideRange = range.lowerBound - 0.01
        } else {
            outsideRange = range.upperBound + 0.01
        }

        let json = validJSON(
            similarity: outsideRange
        )

        #expect(
            throws: WordGeneratorError.noPairsAvailable
        ) {
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )
        }
    }

    // MARK: - Duplicate Concepts

    @Test
    func parseAndValidateJSON_skipsDuplicateConceptsAcrossPairs() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = """
        [
          {
            "civilian": "cat",
            "undercover": "dog",
            "similarity": \(similarity)
          },
          {
            "civilian": "dog",
            "undercover": "wolf",
            "similarity": \(similarity)
          },
          {
            "civilian": "lion",
            "undercover": "tiger",
            "similarity": \(similarity)
          }
        ]
        """

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animals",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 2)

        #expect(
            result[0].civilian.localized(for: .english)
                == "cat"
        )

        #expect(
            result[1].civilian.localized(for: .english)
                == "lion"
        )
    }

    // MARK: - Multiple Valid Pairs

    @Test
    func parseAndValidateJSON_returnsAllValidPairs() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = """
        [
          {
            "civilian": "cat",
            "undercover": "dog",
            "similarity": \(similarity)
          },
          {
            "civilian": "lion",
            "undercover": "tiger",
            "similarity": \(similarity)
          },
          {
            "civilian": "apple",
            "undercover": "orange",
            "similarity": \(similarity)
          }
        ]
        """

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "mixed",
                language: .english,
                difficulty: difficulty
            )

        #expect(result.count == 3)
    }

    // MARK: - Localization

    @Test
    func parseAndValidateJSON_storesWordsUnderRequestedLanguage() throws {

        let difficulty = PairDifficulty.allCases.first!

        let similarity = validSimilarity(for: difficulty)

        let json = validJSON(
            civilian: "chat",
            undercover: "chien",
            similarity: similarity
        )

        let result =
            try FoundationModelsWordGenerator.parseAndValidateJSON(
                json,
                topic: "animaux",
                language: .french,
                difficulty: difficulty
            )

        #expect(result.count == 1)

        #expect(
            result[0].civilian.localized(for: .french)
                == "chat"
        )

        #expect(
            result[0].undercover.localized(for: .french)
                == "chien"
        )

        #expect(result[0].topic == "animaux")
    }
}
