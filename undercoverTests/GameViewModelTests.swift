//
//  GameViewModelTests.swift
//  undercoverTests
//
//  Created by Iheb on 10/09/2026.
//

import Testing
@testable import undercover
internal import Foundation

private enum FakeProviderError: LocalizedError {
    case generationFailed

    var errorDescription: String? {
        "Generation failed for test"
    }
}

@MainActor
private final class FakeWordPairProvider: WordPairProviding {
    private let result: Result<WordPair, any Error>

    init(result: Result<WordPair, any Error>) {
        self.result = result
    }

    func prepareIfNeeded(
        playerCount: Int,
        topic: String?,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) {}

    func nextPair(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) async throws -> WordPair {
        try result.get()
    }

    func reset() {}
}

@MainActor
struct GameViewModelTests {

    // MARK: - Helpers

    private func makePair() -> WordPair {
        WordPair(
            civilian: LocalizedWord(values: ["en": "cat"]),
            undercover: LocalizedWord(values: ["en": "dog"]),
            topic: "animals",
            similarity: 0.62
        )
    }

    private func makeViewModel(
        result: Result<WordPair, any Error> = .success(
            WordPair(
                civilian: LocalizedWord(values: ["en": "cat"]),
                undercover: LocalizedWord(values: ["en": "dog"]),
                topic: "animals",
                similarity: 0.62
            )
        )
    ) -> GameViewModel {
        GameViewModel(
            wordPairProvider: FakeWordPairProvider(result: result)
        )
    }

    private func addThreePlayers(to viewModel: GameViewModel) {
        viewModel.players = [
            Player(name: "Alice"),
            Player(name: "Bob"),
            Player(name: "Charlie")
        ]

        viewModel.selectedTopic = "animals"
    }

    private func addFourPlayers(to viewModel: GameViewModel) {
        viewModel.players = [
            Player(name: "Alice"),
            Player(name: "Bob"),
            Player(name: "Charlie"),
            Player(name: "David")
        ]

        viewModel.selectedTopic = "animals"
        viewModel.mrWhiteModeEnabled = true
    }

    private func revealAllPlayers(in viewModel: GameViewModel) {
        for _ in viewModel.players.indices {
            viewModel.revealTapped()
            viewModel.revealNext()
        }
    }

    // MARK: - Starting the game

    @Test
    func startGame_withGeneratedPair_entersRevealPhase() async {
        let viewModel = makeViewModel()
        addThreePlayers(to: viewModel)

        await viewModel.startGame()

        #expect(viewModel.assignments.count == 3)
        #expect(viewModel.rolesByPlayer.count == 3)
        #expect(viewModel.undercoverPlayerID != nil)
        #expect(viewModel.currentCivilianWord == "cat")
        #expect(viewModel.currentUndercoverWord == "dog")
        #expect(viewModel.wordGeneratorError == nil)
        #expect(viewModel.isGeneratingWords == false)

        if case .reveal(index: 0, step: .passDevice) = viewModel.gameState {
            #expect(true)
        } else {
            Issue.record("Expected game to enter the first reveal screen")
        }
    }

    @Test
    func startGame_withFewerThanThreePlayers_doesNothing() async {
        let viewModel = makeViewModel()

        viewModel.players = [
            Player(name: "Alice"),
            Player(name: "Bob")
        ]

        await viewModel.startGame()

        #expect(viewModel.gameState == .setup)
        #expect(viewModel.assignments.isEmpty)
        #expect(viewModel.rolesByPlayer.isEmpty)
        #expect(viewModel.isGeneratingWords == false)
    }

    @Test
    func startGame_whenProviderFails_setsAnErrorAndDoesNotRevealWords() async {
        let viewModel = makeViewModel(
            result: .failure(FakeProviderError.generationFailed)
        )

        addThreePlayers(to: viewModel)

        await viewModel.startGame()

        #expect(viewModel.isGeneratingWords == false)
        #expect(viewModel.wordGeneratorError != nil)
        #expect(viewModel.assignments.isEmpty)
        #expect(viewModel.rolesByPlayer.isEmpty)

        if case .reveal = viewModel.gameState {
            Issue.record("The game must not reveal words after generation fails")
        } else {
            #expect(true)
        }
    }

    // MARK: - Reveal and voting

    @Test
    func eliminatingUndercoverWithThreePlayers_makesCiviliansWin() async throws {
        let viewModel = makeViewModel()
        addThreePlayers(to: viewModel)

        await viewModel.startGame()
        revealAllPlayers(in: viewModel)

        #expect(viewModel.gameState == .discussion(round: 1))

        let undercoverID = try #require(viewModel.undercoverPlayerID)

        viewModel.enterVoting()
        viewModel.selectedVotePlayerID = undercoverID
        viewModel.finishVoting()

        #expect(viewModel.gameState == .results(.civiliansWin))

        let undercover = try #require(
            viewModel.players.first(where: { $0.id == undercoverID })
        )

        #expect(undercover.isEliminated)
    }

    // MARK: - Mr White

    @Test
    func mrWhiteCorrectGuess_makesMrWhiteWin() async throws {
        let viewModel = makeViewModel()
        addFourPlayers(to: viewModel)

        await viewModel.startGame()
        revealAllPlayers(in: viewModel)

        let mrWhiteID = try #require(viewModel.mrWhitePlayerID)

        viewModel.enterVoting()
        viewModel.selectedVotePlayerID = mrWhiteID
        viewModel.finishVoting()

        #expect(viewModel.gameState == .mrWhiteGuess(round: 1))

        viewModel.mrWhiteGuessInput = "cat"
        viewModel.submitMrWhiteGuess()

        #expect(viewModel.gameState == .results(.mrWhiteWins))
    }

    @Test
    func mrWhiteWrongGuess_continuesTheGameWhenUndercoverRemains() async throws {
        let viewModel = makeViewModel()
        addFourPlayers(to: viewModel)

        await viewModel.startGame()
        revealAllPlayers(in: viewModel)

        let mrWhiteID = try #require(viewModel.mrWhitePlayerID)

        viewModel.enterVoting()
        viewModel.selectedVotePlayerID = mrWhiteID
        viewModel.finishVoting()

        viewModel.mrWhiteGuessInput = "elephant"
        viewModel.submitMrWhiteGuess()

        #expect(viewModel.gameState == .discussion(round: 2))
    }

    // MARK: - Replay and new game

    @Test
    func replay_restoresEliminatedPlayersAndStartsANewRound() async throws {
        let viewModel = makeViewModel()
        addThreePlayers(to: viewModel)

        await viewModel.startGame()
        revealAllPlayers(in: viewModel)

        let undercoverID = try #require(viewModel.undercoverPlayerID)

        viewModel.enterVoting()
        viewModel.selectedVotePlayerID = undercoverID
        viewModel.finishVoting()

        var hasEliminatedPlayer = false

        for player in viewModel.players {
            if player.isEliminated {
                hasEliminatedPlayer = true
                break
            }
        }

        #expect(hasEliminatedPlayer)

        await viewModel.replay()

        var allPlayersAreActive = true

        for player in viewModel.players {
            if player.isEliminated {
                allPlayersAreActive = false
                break
            }
        }

        #expect(allPlayersAreActive)

        await viewModel.replay()

        #expect(viewModel.players.allSatisfy { !$0.isEliminated })
        #expect(viewModel.assignments.count == 3)
        #expect(viewModel.rolesByPlayer.count == 3)

        if case .reveal = viewModel.gameState {
            #expect(true)
        } else {
            Issue.record("Replay should start a new reveal phase")
        }
    }

    @Test
    func newGame_clearsAllGameDataAndReturnsToSetup() async {
        let viewModel = makeViewModel()
        addThreePlayers(to: viewModel)

        await viewModel.startGame()

        viewModel.newGame()

        #expect(viewModel.gameState == .setup)
        #expect(viewModel.players.isEmpty)
        #expect(viewModel.assignments.isEmpty)
        #expect(viewModel.rolesByPlayer.isEmpty)
        #expect(viewModel.revealOrder.isEmpty)
        #expect(viewModel.undercoverPlayerID == nil)
        #expect(viewModel.mrWhitePlayerID == nil)
        #expect(viewModel.currentCivilianWord.isEmpty)
        #expect(viewModel.currentUndercoverWord.isEmpty)
        #expect(viewModel.selectedVotePlayerID == nil)
        #expect(viewModel.mrWhiteGuessInput.isEmpty)
    }
}
