//
//  GameStateMachine.swift
//  undercoverApp
//
//  Pure value-type FSM. Zero dependencies on UI or services.
//  All transitions are deterministic and fully unit-testable.
//

import Foundation

// MARK: - State

public enum GameState: Equatable, Sendable {
    case setup
    case loadingWords
    case reveal(index: Int, step: RevealStep)
    case discussion(round: Int)
    case voting(round: Int)
    case mrWhiteGuess(round: Int)
    case results(GameResult)
}

public enum RevealStep: Equatable, Sendable {
    case passDevice
    case showWord
}

// MARK: - Result

public enum GameResult: Equatable, Sendable {
    case civiliansWin
    case undercoverWins
    case mrWhiteWins
    
    public var title: String {
        switch self {
            case .civiliansWin:   return "Civilians Win!"
            case .undercoverWins: return "Undercover Wins!"
            case .mrWhiteWins:    return "Mr. White Wins!"
        }
    }
    
    public var emoji: String {
        switch self {
            case .civiliansWin:   return "🎉"
            case .undercoverWins: return "😈"
            case .mrWhiteWins:    return "🃏"
        }
    }
}

// MARK: - Events

public enum GameEvent: Sendable {
    case startLoading
    case wordsReady(playerCount: Int)
    case revealTapped
    case revealNext(totalPlayers: Int)
    case discussionEnded(round: Int)
    case votingFinished(eliminated: PlayerRole, aliveCivilians: Int, aliveUndercover: Int, aliveMrWhite: Int, round: Int)
    case skipVoting(round: Int)
    case mrWhiteGuessResult(correct: Bool, aliveCivilians: Int, aliveUndercover: Int, round: Int)
    case replay(playerCount: Int)
    case newGame
}

// MARK: - Machine

public struct GameStateMachine: Sendable, Equatable {
    
    public private(set) var state: GameState = .setup
    
    public init(initialState: GameState = .setup) {
        self.state = initialState
    }
    
    /// Apply an event. Returns `true` if state changed.
    @discardableResult
    public mutating func handle(_ event: GameEvent) -> Bool {
        let next = transition(from: state, on: event)
        guard next != state else { return false }
        state = next
        return true
    }
    
    // MARK: - Transition table
    
    private func transition(from state: GameState, on event: GameEvent) -> GameState {
        switch (state, event) {
                
                // ── Setup ──────────────────────────────────────────────────────────
            case (.setup, .startLoading):
                return .loadingWords
                
                // ── Loading ────────────────────────────────────────────────────────
            case (.loadingWords, .wordsReady(let count)) where count > 0:
                return .reveal(index: 0, step: .passDevice)
                
            case (.loadingWords, .wordsReady):
                // 0 players — back to setup defensively
                return .setup
                
                // ── Reveal ─────────────────────────────────────────────────────────
            case (.reveal(let idx, .passDevice), .revealTapped):
                return .reveal(index: idx, step: .showWord)
                
            case (.reveal(let idx, .showWord), .revealNext(let total)):
                let next = idx + 1
                return next < total
                ? .reveal(index: next, step: .passDevice)
                : .discussion(round: 1)
                
                // ── Discussion ─────────────────────────────────────────────────────
            case (.discussion, .discussionEnded(let round)):
                return .voting(round: round)
            case (.discussion(let round), .skipVoting):
                return .discussion(round: round + 1)
                
                // ── Voting ─────────────────────────────────────────────────────────
            case (.voting(let round), .votingFinished(
                let role,
                let civilians,
                let undercover,
                let mrWhite,
                _
            )):
                return nextStateAfterElimination(
                    role: role,
                    aliveCivilians: civilians,
                    aliveUndercover: undercover,
                    aliveMrWhite: mrWhite,
                    round: round
                )
                
                // ── Mr. White Guess ────────────────────────────────────────────────
                // ── Mr. White Guess ────────────────────────────────────────────────
            case (.mrWhiteGuess, .mrWhiteGuessResult(
                true, _, _, _
            )):
                // Mr. White guessed the civilian word.
                return .results(.mrWhiteWins)
                
            case (.mrWhiteGuess(let round), .mrWhiteGuessResult(
                false,
                let civilians,
                let undercover,
                _
            )):
                // Mr. White guessed incorrectly.
                // He is already eliminated.
                
                if undercover == 0 {
                    // No Undercover remains.
                    return .results(.civiliansWin)
                }
                
                if undercover >= civilians {
                    // Undercover has reached parity or majority.
                    return .results(.undercoverWins)
                }
                
                // Game continues.
                return .discussion(round: round + 1)
                
                // ── Results ────────────────────────────────────────────────────────
            case (.results, .replay(let count)):
                return count > 0 ? .loadingWords : .setup
                
            case (_, .newGame):
                return .setup
                
            default:
                return state    // Ignore invalid transitions — no crash
        }
    }
    
    // MARK: - Win condition logic
    
    private func nextStateAfterElimination(
        role: PlayerRole,
        aliveCivilians: Int,
        aliveUndercover: Int,
        aliveMrWhite: Int,
        round: Int
    ) -> GameState {
        
        switch role {
            case .mrWhite:
                return .mrWhiteGuess(round: round)
                
            case .undercover:
                // Handle eliminated Undercover player
                if aliveUndercover == 0 {
                    // No Undercover remains
                    if isOnlyCivilianAndMrWhiteRemaining(
                        aliveCivilians, aliveUndercover, aliveMrWhite
                    ) {
                        // Only Civilian + Mr. White remain
                        return .mrWhiteGuess(round: round)
                    }
                    if isOnlyCivililiansRemaining(
                        aliveCivilians, aliveUndercover, aliveMrWhite
                    ) {
                        // Only Civilians remain
                        return .results(.civiliansWin)
                    }
                    // Civilians + Mr. White remain
                    return .discussion(round: round + 1)
                }
                
                // Undercover still alive, check for Undercover + Mr. White only
                if isOnlyUndercoverAndMrWhiteRemaining(
                    aliveCivilians, aliveUndercover, aliveMrWhite
                ) {
                    return .mrWhiteGuess(round: round)
                }
                
                // Mr. White is still alive
                if aliveMrWhite > 0 {
                    return .discussion(round: round + 1)
                }
                
                // Normal Undercover win condition (parity or majority)
                if shouldUndercoverWin(aliveCivilians, aliveUndercover, aliveMrWhite) {
                    return .results(.undercoverWins)
                }
                
                // Continue to next round
                return .discussion(round: round + 1)
                
            case .civilian:
                // Handle eliminated Civilian player
                // Check special role combinations first
                if isOnlyCivilianAndMrWhiteRemaining(
                    aliveCivilians, aliveUndercover, aliveMrWhite
                ) {
                    return .mrWhiteGuess(round: round)
                }
                if isOnlyUndercoverAndMrWhiteRemaining(
                    aliveCivilians, aliveUndercover, aliveMrWhite
                ) {
                    return .mrWhiteGuess(round: round)
                }
                
                // If no Undercover remains
                if aliveUndercover == 0 {
                    if isOnlyCivililiansRemaining(
                        aliveCivilians, aliveUndercover, aliveMrWhite
                    ) {
                        return .results(.civiliansWin)
                    }
                    // Only Civilians + Mr. White remain (already handled above)
                    // Or multiple Civilians remain
                    return .discussion(round: round + 1)
                }
                
                // Mr. White is still alive
                if aliveMrWhite > 0 {
                    return .discussion(round: round + 1)
                }
                
                // No Mr. White remains - check for Undercover win
                if shouldUndercoverWin(aliveCivilians, aliveUndercover, aliveMrWhite) {
                    return .results(.undercoverWins)
                }
                
                // Continue to next round
                return .discussion(round: round + 1)
        }
    }
    
    // MARK: - Win Condition Helpers
    
    private func isOnlyCivililiansRemaining(
        _ civilians: Int,
        _ undercover: Int,
        _ mrWhite: Int
    ) -> Bool {
        civilians >= 2 && undercover == 0 && mrWhite == 0
    }
    
    private func isOnlyCivilianAndMrWhiteRemaining(
        _ civilians: Int,
        _ undercover: Int,
        _ mrWhite: Int
    ) -> Bool {
        civilians == 1 && undercover == 0 && mrWhite == 1
    }
    
    private func isOnlyUndercoverAndMrWhiteRemaining(
        _ civilians: Int,
        _ undercover: Int,
        _ mrWhite: Int
    ) -> Bool {
        civilians == 0 && undercover == 1 && mrWhite == 1
    }
    
    private func shouldUndercoverWin(
        _ civilians: Int,
        _ undercover: Int,
        _ mrWhite: Int
    ) -> Bool {
        mrWhite == 0 && undercover >= civilians
    }
}
