//
//  WordPairProvider.swift
//  undercoverApp
//
//  Game-level word-pair cache.
//
//  Flow:
//
//  GAME START
//      Local → 1 playable pair
//      LLM   → background refill to 4
//
//  GAMEPLAY
//      Cache first
//      Cache <= 2 → LLM background refill
//      Cache empty → wait for LLM
//

import Foundation

@MainActor
final class WordPairProvider {

    // MARK: - Configuration

    private struct WordBatchConfiguration: Equatable {
        let topic: String
        let language: AppLanguage
        let difficulty: PairDifficulty
    }

    private let refillThreshold = 2
    private let targetPreparedPairs = 4
    private let maxPreparationAttempts = 20

    // MARK: - Cache

    private var preparedWordPairs: [WordPair] = []
    private var preparedConfiguration: WordBatchConfiguration?

    private var initialLocalTask: Task<Void, Never>?
    private var llmPreparationTask: Task<Void, Never>?

    private var preparationID = UUID()

    // MARK: - Services

    private let pairStore = PlayedPairStore()
    private let nextPairMutex = AsyncMutex()

    private lazy var generatorService = WordGeneratorService(
        generators: [
            LocalWordGenerator(),
            FoundationModelsWordGenerator()
        ]
    )

    // MARK: - Game Start

    /// Starts Local generation for the first playable pair.
    ///
    /// The Local task is awaited by `nextPair()`.
    /// LLM preparation starts after Local succeeds and runs in background.
    func prepareForGameStart(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) {
        guard playerCount >= 3 else {
            return
        }

        let configuration = WordBatchConfiguration(
            topic: topic,
            language: language,
            difficulty: difficulty
        )

        if preparedConfiguration != configuration {
            resetPreparation(for: configuration)
        }

        // We already have something playable.
        if !preparedWordPairs.isEmpty {
            startLLMPreparationIfNeeded(
                configuration: configuration,
                preparationID: preparationID
            )
            return
        }

        // Local generation is already running.
        guard initialLocalTask == nil else {
            return
        }

        let currentPreparationID = preparationID

        initialLocalTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            defer {
                if self.preparationID == currentPreparationID {
                    self.initialLocalTask = nil
                }
            }

            do {
                let used = await self.pairStore.usedConcepts(
                    for: configuration.topic
                )

                let cached = await self.cacheConcepts()

                let exclusions = used.union(cached)

                let pair = try await self.generatorService.generateLocalPair(
                    topic: configuration.topic,
                    language: configuration.language,
                    difficulty: configuration.difficulty,
                    excluding: exclusions
                )

                guard !Task.isCancelled else {
                    return
                }

                let inserted = await self.insertPreparedPair(
                    pair,
                    configuration: configuration
                )

                guard inserted else {
                    return
                }

                print("✅ [Provider] Initial Local pair loaded.")
                print(
                    "📦 [Provider] Cache: " +
                    "\(self.preparedWordPairs.count)/" +
                    "\(self.targetPreparedPairs)"
                )

                // Start LLM only after Local produced a playable pair.
                self.startLLMPreparationIfNeeded(
                    configuration: configuration,
                    preparationID: currentPreparationID
                )

            } catch is CancellationError {
                print("🛑 [Provider] Initial Local preparation cancelled.")

            } catch {
                print(
                    "⚠️ [Provider] Initial Local generation failed: \(error)"
                )

                // Local failed → allow LLM to provide the first pair.
                self.startLLMPreparationIfNeeded(
                    configuration: configuration,
                    preparationID: currentPreparationID
                )
            }
        }
    }

    // MARK: - LLM Preparation

    /// Starts LLM background generation.
    ///
    /// This method NEVER waits for the generated pair.
    private func startLLMPreparationIfNeeded(
        configuration: WordBatchConfiguration,
        preparationID: UUID
    ) {
        guard preparedConfiguration == configuration else {
            return
        }

        guard preparedWordPairs.count < targetPreparedPairs else {
            return
        }

        guard llmPreparationTask == nil else {
            return
        }

        llmPreparationTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            defer {
                if self.preparationID == preparationID {
                    self.llmPreparationTask = nil
                }
            }

            var attempts = 0

            while !Task.isCancelled,
                  attempts < self.maxPreparationAttempts {

                guard self.preparedConfiguration == configuration,
                      self.preparedWordPairs.count < self.targetPreparedPairs
                else {
                    break
                }

                attempts += 1

                let used = await self.pairStore.usedConcepts(
                    for: configuration.topic
                )

                let cached = await self.cacheConcepts()

                let exclusions = used.union(cached)

                do {
                    print(
                        """
                        🧠 [Provider] LLM refill
                        Cache: \(self.preparedWordPairs.count)/\(self.targetPreparedPairs)
                        Exclusions: \(exclusions.count)
                        """
                    )

                    let pair = try await self.generatorService
                        .generateBackgroundPair(
                            topic: configuration.topic,
                            language: configuration.language,
                            difficulty: configuration.difficulty,
                            excluding: exclusions
                        )

                    guard !Task.isCancelled else {
                        break
                    }

                    let inserted = await self.insertPreparedPair(
                        pair,
                        configuration: configuration
                    )

                    if inserted {
                        print("✅ [Provider] LLM pair added.")
                        print(
                            "📦 [Provider] Cache: " +
                            "\(self.preparedWordPairs.count)/" +
                            "\(self.targetPreparedPairs)"
                        )
                    } else {
                        print("⚠️ [Provider] LLM pair rejected.")
                    }

                } catch is CancellationError {
                    break

                } catch {
                    print(
                        "⚠️ [Provider] LLM preparation failed: \(error)"
                    )

                    // Don't continuously hammer Foundation Models.
                    break
                }
            }
        }
    }

    // MARK: - Insert

    @discardableResult
    private func insertPreparedPair(
        _ pair: WordPair,
        configuration: WordBatchConfiguration
    ) async -> Bool {
        guard preparedConfiguration == configuration else {
            return false
        }

        let pairConcepts = NormalizationUtility.conceptsFromPair(
            civilian: pair.civilian.firstNonEmpty,
            undercover: pair.undercover.firstNonEmpty
        )

        let used = await pairStore.usedConcepts(
            for: configuration.topic
        )

        return await nextPairMutex.withLock {
            guard preparedConfiguration == configuration else {
                return false
            }

            guard preparedWordPairs.count < targetPreparedPairs else {
                return false
            }

            let cached = currentCacheConcepts()

            guard pairConcepts.isDisjoint(with: used) else {
                print("⚠️ [Provider] Rejected pair: already played.")
                return false
            }

            guard pairConcepts.isDisjoint(with: cached) else {
                print("⚠️ [Provider] Rejected pair: conflicts with cache.")
                return false
            }

            preparedWordPairs.append(pair)
            return true
        }
    }

    // MARK: - Setup Preparation

    /// Called when setup changes.
    ///
    /// This only starts LLM background preparation.
    /// The initial Local pair is handled by `prepareForGameStart()`.
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
            reset()
            return
        }

        let configuration = WordBatchConfiguration(
            topic: topic,
            language: language,
            difficulty: difficulty
        )

        if preparedConfiguration != configuration {
            resetPreparation(for: configuration)
        }

        startLLMPreparationIfNeeded(
            configuration: configuration,
            preparationID: preparationID
        )
    }

    // MARK: - Next Pair

    /// Returns a playable pair.
    ///
    /// Flow:
    ///
    /// 1. Start Local preparation if necessary.
    /// 2. Wait for Local only.
    /// 3. Consume cached pair.
    /// 4. If cache <= threshold, start LLM refill.
    /// 5. If cache is empty, wait for LLM.
    func nextPair(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) async throws -> WordPair {
        prepareForGameStart(
            playerCount: playerCount,
            topic: topic,
            language: language,
            difficulty: difficulty
        )

        // Initial game start waits for Local.
        if let localTask = initialLocalTask {
            await localTask.value
        }

        // ---------------------------------------------------------
        // CACHE FIRST
        // ---------------------------------------------------------

        if let pair = await consumeCachedPair(
            topic: topic,
            language: language,
            difficulty: difficulty
        ) {
            await handleCacheAfterConsumption(
                playerCount: playerCount,
                topic: topic,
                language: language,
                difficulty: difficulty
            )

            return pair
        }

        // ---------------------------------------------------------
        // CACHE EMPTY
        //
        // Only NOW do we wait for LLM.
        // ---------------------------------------------------------

        prepareIfNeeded(
            playerCount: playerCount,
            topic: topic,
            language: language,
            difficulty: difficulty
        )

        if let llmTask = llmPreparationTask {
            await llmTask.value
        }

        // LLM may have populated the cache.
        if let pair = await consumeCachedPair(
            topic: topic,
            language: language,
            difficulty: difficulty
        ) {
            await handleCacheAfterConsumption(
                playerCount: playerCount,
                topic: topic,
                language: language,
                difficulty: difficulty
            )

            return pair
        }

        throw WordPairProviderError.unableToProvidePair
    }

    // MARK: - Cache Consumption

    private func consumeCachedPair(
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) async -> WordPair? {
        let used = await pairStore.usedConcepts(
            for: topic
        )

        let pair: WordPair? = await nextPairMutex.withLock {
            guard let configuration = preparedConfiguration,
                  configuration.topic == topic,
                  configuration.language == language,
                  configuration.difficulty == difficulty
            else {
                return nil
            }

            guard let index = preparedWordPairs.firstIndex(
                where: { pair in
                    let concepts = NormalizationUtility.conceptsFromPair(
                        civilian: pair.civilian.firstNonEmpty,
                        undercover: pair.undercover.firstNonEmpty
                    )

                    return concepts.isDisjoint(with: used)
                }
            ) else {
                return nil
            }

            return preparedWordPairs.remove(at: index)
        }

        guard let pair else {
            return nil
        }

        do {
            try await pairStore.markAsPlayed(
                civilian: pair.civilian.firstNonEmpty,
                undercover: pair.undercover.firstNonEmpty,
                topic: topic
            )

            return pair

        } catch {
            await nextPairMutex.withLock {
                preparedWordPairs.insert(pair, at: 0)
            }

            return nil
        }
    }

    // MARK: - Cache Refill

    private func handleCacheAfterConsumption(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) {
        let cacheCount = preparedWordPairs.count

        print(
            "🎮 [Provider] Pair consumed."
        )

        print(
            "📦 [Provider] Cache: " +
            "\(cacheCount)/\(targetPreparedPairs)"
        )

        guard cacheCount <= refillThreshold else {
            return
        }

        prepareIfNeeded(
            playerCount: playerCount,
            topic: topic,
            language: language,
            difficulty: difficulty
        )
    }

    // MARK: - Cache Helpers

    private func cacheConcepts() async -> Set<String> {
        await nextPairMutex.withLock {
            currentCacheConcepts()
        }
    }

    private func currentCacheConcepts() -> Set<String> {
        var concepts = Set<String>()

        for pair in preparedWordPairs {
            concepts.formUnion(
                NormalizationUtility.conceptsFromPair(
                    civilian: pair.civilian.firstNonEmpty,
                    undercover: pair.undercover.firstNonEmpty
                )
            )
        }

        return concepts
    }

    // MARK: - Reset

    private func resetPreparation(
        for configuration: WordBatchConfiguration
    ) {
        initialLocalTask?.cancel()
        initialLocalTask = nil

        llmPreparationTask?.cancel()
        llmPreparationTask = nil

        preparedWordPairs.removeAll()
        preparedConfiguration = configuration

        preparationID = UUID()
    }

    func reset() {
        initialLocalTask?.cancel()
        initialLocalTask = nil

        llmPreparationTask?.cancel()
        llmPreparationTask = nil

        preparedWordPairs.removeAll()
        preparedConfiguration = nil

        preparationID = UUID()
    }
}

// MARK: - Errors

private enum WordPairProviderError: Error {
    case unableToProvidePair
}
