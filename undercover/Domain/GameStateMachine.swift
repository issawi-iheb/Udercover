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
            // Mr. White was eliminated.
            // He always gets one final chance to guess the civilian word.
            return .mrWhiteGuess(round: round)

        case .undercover:

            // No Undercover remains.
            if aliveUndercover == 0 {
                // If Mr. White is also gone, civilians win.
                if aliveMrWhite == 0 {
                    return .results(.civiliansWin)
                }

                // Mr. White is still alive.
                // The group can continue and eventually vote him out.
                return .discussion(round: round + 1)
            }

            // FINAL DUEL:
            // Only Mr. White and the Undercover remain.
            //
            // There is no point in voting between two players.
            // Mr. White gets the final guess immediately.
            if aliveCivilians == 0 &&
               aliveUndercover == 1 &&
               aliveMrWhite == 1 {
                return .mrWhiteGuess(round: round)
            }

            // Undercover cannot win while Mr. White is still alive.
            if aliveMrWhite > 0 {
                return .discussion(round: round + 1)
            }

            // Normal Undercover parity rule.
            if aliveUndercover >= aliveCivilians {
                return .results(.undercoverWins)
            }

            return .discussion(round: round + 1)

        case .civilian:

            // FINAL DUEL:
            // Civilian has just been eliminated and only
            // Mr. White + Undercover remain.
            //
            // Skip another voting round.
            if aliveCivilians == 0 &&
               aliveUndercover == 1 &&
               aliveMrWhite == 1 {
                return .mrWhiteGuess(round: round)
            }

            // Mr. White is still alive.
            // Undercover does not automatically win yet.
            if aliveMrWhite > 0 {
                return .discussion(round: round + 1)
            }

            // No Undercover remains.
            if aliveUndercover == 0 {
                return .results(.civiliansWin)
            }

            // Normal Undercover parity rule.
            if aliveUndercover >= aliveCivilians {
                return .results(.undercoverWins)
            }

            return .discussion(round: round + 1)
        }
    }
}
