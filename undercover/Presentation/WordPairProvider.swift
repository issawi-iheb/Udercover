//  WordPairProvider.swift
//  undercover
//
//  Created by Iheb on 21/08/2026.
//

import Foundation

@MainActor
final class WordPairProvider {

    // MARK: - Configuration

    private struct WordBatchConfiguration: Equatable {
        let topic: String
        let language: AppLanguage
        let difficulty: PairDifficulty

        static func == (lhs: WordBatchConfiguration, rhs: WordBatchConfiguration) -> Bool {
            lhs.topic == rhs.topic &&
            lhs.language == rhs.language &&
            lhs.difficulty == rhs.difficulty
        }
    }

    // MARK: - Cache

    private var preparedWordPairs: [WordPair] = []
    private var preparedConfiguration: WordBatchConfiguration?
    private var preparationTask: Task<Void, Never>?
    private var preparationID = UUID()

    private let preparationBatchSize = 3

    // MARK: - Services

    private let pairStore = PlayedPairStore()
    private let nextPairMutex = AsyncMutex()
    
    private lazy var generatorService = WordGeneratorService(
        generators: [
            LocalWordGenerator(),
            FoundationModelsWordGenerator()
        ]
    )

    // MARK: - Preparation

    func prepareIfNeeded(
        playerCount: Int,
        topic: String?,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) {
        guard playerCount >= 3,
              let topic,
              !topic.isEmpty
        else {
            preparationTask?.cancel()
            preparationTask = nil
            preparedWordPairs.removeAll()
            preparedConfiguration = nil
            return
        }

        let configuration = WordBatchConfiguration(
            topic: topic,
            language: language,
            difficulty: difficulty
        )

        // Already enough cached pairs.
        if preparedConfiguration == configuration,
           preparedWordPairs.count >= preparationBatchSize {
            return
        }

        // Configuration changed.
        if preparedConfiguration != configuration {
            preparationTask?.cancel()
            preparationTask = nil
            preparationID = UUID()

            preparedWordPairs.removeAll()
            preparedConfiguration = configuration
        }

        // Already generating.
        guard preparationTask == nil else {
            return
        }
        
        let currentPreparationID = preparationID
        
        preparationTask = Task { [weak self] in
            guard let self else {
                return
            }
            var excluded = await pairStore.usedConcepts(
                for: configuration.topic
            )

            while !Task.isCancelled {

                let currentCount = preparedWordPairs.count

                if currentCount >= preparationBatchSize {
                    break
                }

                do {
                    let pair = try await generatorService.randomPair(
                        topic: configuration.topic,
                        language: configuration.language,
                        difficulty: configuration.difficulty,
                        excluding: excluded
                    )

                    guard preparedConfiguration == configuration else {
                        break
                    }

                    preparedWordPairs.append(pair)

                    excluded.formUnion(
                        NormalizationUtility.conceptsFromPair(
                            civilian: pair.civilian.firstNonEmpty,
                            undercover: pair.undercover.firstNonEmpty
                        )
                    )

                } catch {
                    print(
                        "⚠️ Word preparation stopped:",
                        error.localizedDescription
                    )

                    break
                }
            }

            if preparationID == currentPreparationID {
                preparationTask = nil
            }
        }
    }

    // MARK: - Resolve

    func resolvePair(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) async throws -> WordPair {

        if let configuration = preparedConfiguration,
           configuration.topic == topic,
           configuration.language == language,
           configuration.difficulty == difficulty {

            if let index = preparedWordPairs.firstIndex(where: { pair in

                let pairConcepts = NormalizationUtility.conceptsFromPair(
                    civilian: pair.civilian.firstNonEmpty,
                    undercover: pair.undercover.firstNonEmpty
                )

                return pairConcepts.isDisjoint(with: excluding)
            }) {

                return preparedWordPairs.remove(at: index)
            }
        }

        // Generate a new pair when the prepared cache is empty.
        return try await generatorService.randomPair(
            topic: topic,
            language: language,
            difficulty: difficulty,
            excluding: excluding
        )
    }

    // MARK: - Reset

    func reset() {
        preparationTask?.cancel()
        preparationTask = nil
        preparationID = UUID()

        preparedWordPairs.removeAll()
        preparedConfiguration = nil
    }

    // MARK: - Fallback

    private func fallbackPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty,
        excluding: Set<String>
    ) throws -> WordPair {

        let repository = WordRepository()

        if let pair = repository.randomPair(
            topic: topic,
            language: language,
            difficulty: difficulty,
            excluding: excluding
        ) {
            return pair
        }

        throw WordGeneratorError.noPairsAvailable
    }

    func nextPair(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) async throws -> WordPair {

        try await nextPairMutex.withLock {

            let used = await pairStore.usedConcepts(
                for: topic
            )

            let pair = try await resolvePair(
                playerCount: playerCount,
                topic: topic,
                language: language,
                difficulty: difficulty,
                excluding: used
            )

            try await pairStore.markAsPlayed(
                civilian: pair.civilian.firstNonEmpty,
                undercover: pair.undercover.firstNonEmpty,
                topic: topic
            )

            return pair
        }
    }
}
