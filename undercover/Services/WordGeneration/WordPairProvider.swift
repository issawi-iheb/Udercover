//
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
    }

    // MARK: - Cache

    private var preparedWordPairs: [WordPair] = []

    private var preparedConfiguration:
        WordBatchConfiguration?

    private var preparationTask:
        Task<Void, Never>?

    private var preparationID = UUID()

    private let refillThreshold = 2

    private let targetPreparedPairs = 4

    // Prevent endless generation if a generator repeatedly
    // returns invalid/duplicate pairs.
    private let maximumGenerationAttempts = 8

    // MARK: - Services

    private let pairStore = PlayedPairStore()

    private let nextPairMutex = AsyncMutex()

    private lazy var generatorService =
        WordGeneratorService(
            generators: [
                LocalWordGenerator(),
                FoundationModelsWordGenerator()
            ]
        )

    // MARK: - Snapshot

    private enum NextPairSnapshot {

        case cached(WordPair)

        case generate(
            exclusions: Set<String>
        )
    }

    // MARK: - Errors

    private enum WordPairProviderError: Error {

        case configurationChanged

        case pairBecameInvalid

        case generationFailed
    }

    // MARK: - Preparation

    /// Starts background preparation if necessary.
    ///
    /// This method NEVER waits for generation.
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

            self.preparationTask?.cancel()
            self.preparationTask = nil

            self.preparedWordPairs.removeAll()
            self.preparedConfiguration = nil

            return
        }

        let configuration =
            WordBatchConfiguration(
                topic: topic,
                language: language,
                difficulty: difficulty
            )

        // ---------------------------------------------------------
        // Configuration changed.
        // ---------------------------------------------------------

        if self.preparedConfiguration != configuration {

            self.preparationTask?.cancel()
            self.preparationTask = nil

            self.preparedWordPairs.removeAll()

            self.preparedConfiguration =
                configuration

            self.preparationID = UUID()
        }

        // ---------------------------------------------------------
        // Cache already full.
        // ---------------------------------------------------------

        guard self.preparedWordPairs.count
                < self.targetPreparedPairs
        else {
            return
        }

        // ---------------------------------------------------------
        // Already preparing.
        // ---------------------------------------------------------

        guard self.preparationTask == nil
        else {
            return
        }

        let currentPreparationID =
            self.preparationID

        self.preparationTask =
            Task { [weak self] in

                guard let self else {
                    return
                }

                await self.prepare(
                    configuration: configuration,
                    preparationID: currentPreparationID
                )
            }
    }

    // MARK: - Prepare

    private func prepare(
        configuration: WordBatchConfiguration,
        preparationID: UUID
    ) async {

        var excluded =
            await self.pairStore.usedConcepts(
                for: configuration.topic
            )

        // Include concepts currently in cache.
        let cachedConcepts =
            self.conceptsInPreparedCache()

        excluded.formUnion(
            cachedConcepts
        )

        while !Task.isCancelled {

            // Configuration changed.
            guard self.preparedConfiguration ==
                    configuration
            else {
                break
            }

            // Target reached.
            guard self.preparedWordPairs.count
                    < self.targetPreparedPairs
            else {
                break
            }

            do {

                let pair =
                    try await self.generatorService.randomPair(
                        topic: configuration.topic,
                        language: configuration.language,
                        difficulty: configuration.difficulty,
                        excluding: excluded
                    )

                guard !Task.isCancelled
                else {
                    break
                }

                let pairConcepts =
                    pair.concepts

                // -------------------------------------------------
                // Validate + insert atomically.
                // -------------------------------------------------

                let inserted =
                    await self.nextPairMutex.withLock {

                        guard self.preparedConfiguration ==
                                configuration
                        else {
                            return false
                        }

                        guard self.preparedWordPairs.count
                                < self.targetPreparedPairs
                        else {
                            return false
                        }

                        let usedNow =
                            await self.pairStore.usedConcepts(
                                for: configuration.topic
                            )

                        let cacheConceptsNow =
                            self.conceptsInPreparedCache()

                        guard pairConcepts.isDisjoint(
                            with: usedNow
                        )
                        else {
                            return false
                        }

                        guard pairConcepts.isDisjoint(
                            with: cacheConceptsNow
                        )
                        else {
                            return false
                        }

                        self.preparedWordPairs.append(
                            pair
                        )

                        return true
                    }

                if inserted {
                    excluded.formUnion(
                        pairConcepts
                    )
                }

            } catch is CancellationError {

                break

            } catch {

                // Don't kill preparation permanently.
                //
                // Give the generator a moment before retrying.
                try? await Task.sleep(
                    for: .milliseconds(200)
                )
            }
        }

        // Only clear the currently active task.
        guard self.preparationID ==
                preparationID
        else {
            return
        }

        self.preparationTask = nil
    }

    // MARK: - Next Pair

    /// Returns the next available word pair.
    ///
    /// Background preparation is NEVER awaited.
    ///
    /// Cached pairs are consumed immediately.
    /// If no cached pair is available, generation happens outside
    /// the mutex.
    func nextPair(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) async throws -> WordPair {

        var attempts = 0

        while attempts < self.maximumGenerationAttempts {

            attempts += 1

            // -----------------------------------------------------
            // PHASE 1
            //
            // Inspect cache under mutex.
            // -----------------------------------------------------

            let snapshot =
                await self.nextPairMutex.withLock {

                    let used =
                        await self.pairStore.usedConcepts(
                            for: topic
                        )

                    // -------------------------------------------------
                    // Try cache first.
                    // -------------------------------------------------

                    if let configuration =
                        self.preparedConfiguration,
                       configuration.topic == topic,
                       configuration.language == language,
                       configuration.difficulty == difficulty {

                        if let index =
                            self.preparedWordPairs.firstIndex(
                                where: { pair in

                                    pair.concepts.isDisjoint(
                                        with: used
                                    )
                                }
                            ) {

                            let pair =
                                self.preparedWordPairs.remove(
                                    at: index
                                )

                            return NextPairSnapshot.cached(
                                pair
                            )
                        }
                    }

                    // -------------------------------------------------
                    // No compatible cached pair.
                    //
                    // Snapshot exclusions.
                    // -------------------------------------------------

                    let cacheConcepts =
                        self.conceptsInPreparedCache()

                    let exclusions =
                        used.union(cacheConcepts)

                    return NextPairSnapshot.generate(
                        exclusions: exclusions
                    )
                }

            // -----------------------------------------------------
            // PHASE 2
            //
            // Generate OUTSIDE mutex.
            // -----------------------------------------------------

            let candidate: WordPair

            switch snapshot {

            case .cached(let cachedPair):

                candidate = cachedPair

            case .generate(let exclusions):

                do {

                    candidate =
                        try await self.generatorService.randomPair(
                            topic: topic,
                            language: language,
                            difficulty: difficulty,
                            excluding: exclusions
                        )

                } catch is CancellationError {

                    throw CancellationError()

                } catch {

                    throw error
                }
            }

            // -----------------------------------------------------
            // PHASE 3
            //
            // Validate + commit.
            // -----------------------------------------------------

            do {

                return try await self.nextPairMutex.withLock {

                    // -------------------------------------------------
                    // Configuration must still match.
                    // -------------------------------------------------

                    guard let configuration =
                        self.preparedConfiguration,
                          configuration.topic == topic,
                          configuration.language == language,
                          configuration.difficulty == difficulty
                    else {

                        // Restore cached pair.
                        if case .cached(let cachedPair) =
                            snapshot {

                            self.preparedWordPairs.append(
                                cachedPair
                            )
                        }

                        throw WordPairProviderError
                            .configurationChanged
                    }

                    // -------------------------------------------------
                    // Reload latest played concepts.
                    // -------------------------------------------------

                    let usedNow =
                        await self.pairStore.usedConcepts(
                            for: topic
                        )

                    // -------------------------------------------------
                    // Validate candidate against current state.
                    // -------------------------------------------------

                    let candidateConcepts =
                        candidate.concepts

                    guard candidateConcepts.isDisjoint(
                        with: usedNow
                    )
                    else {

                        if case .cached(let cachedPair) =
                            snapshot {

                            self.preparedWordPairs.append(
                                cachedPair
                            )
                        }

                        throw WordPairProviderError
                            .pairBecameInvalid
                    }

                    // -------------------------------------------------
                    // A generated candidate must also not collide
                    // with anything currently in the cache.
                    //
                    // Cached candidate was already removed, so it
                    // does not need to be compared with itself.
                    // -------------------------------------------------

                    if case .generate = snapshot {

                        let cacheConcepts =
                            self.conceptsInPreparedCache()

                        guard candidateConcepts.isDisjoint(
                            with: cacheConcepts
                        )
                        else {

                            throw WordPairProviderError
                                .pairBecameInvalid
                        }
                    }

                    // -------------------------------------------------
                    // Mark played while protected by the mutex.
                    // -------------------------------------------------

                    do {

                        try await self.pairStore.markAsPlayed(
                            civilian:
                                candidate.civilian.firstNonEmpty,
                            undercover:
                                candidate.undercover.firstNonEmpty,
                            topic: topic
                        )

                    } catch {

                        // Cached pair was never successfully
                        // committed, therefore restore it.
                        if case .cached(let cachedPair) =
                            snapshot {

                            self.preparedWordPairs.append(
                                cachedPair
                            )
                        }

                        throw error
                    }

                    // -------------------------------------------------
                    // Trigger refill.
                    // -------------------------------------------------

                    if self.preparedWordPairs.count
                        <= self.refillThreshold {

                        self.prepareIfNeeded(
                            playerCount: playerCount,
                            topic: topic,
                            language: language,
                            difficulty: difficulty
                        )
                    }

                    return candidate
                }

            } catch WordPairProviderError.pairBecameInvalid {

                // -----------------------------------------------------
                // Another request won the race.
                //
                // Don't fail the game.
                //
                // Simply retry generation with fresh exclusions.
                // -----------------------------------------------------

                continue

            } catch WordPairProviderError.configurationChanged {

                throw WordPairProviderError
                    .configurationChanged
            }
        }

        throw WordPairProviderError
            .generationFailed
    }

    // MARK: - Helpers

    private func conceptsInPreparedCache()
        -> Set<String> {

        var concepts = Set<String>()

        for pair in self.preparedWordPairs {
            concepts.formUnion(
                pair.concepts
            )
        }

        return concepts
    }

    // MARK: - Reset

    func reset() {

        self.preparationTask?.cancel()
        self.preparationTask = nil

        self.preparationID = UUID()

        self.preparedWordPairs.removeAll()
        self.preparedConfiguration = nil
    }
}
