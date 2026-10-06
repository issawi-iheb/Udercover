//
//  GameEngine.swift
//  undercoverApp
//
//  Pure stateless functions. No stored properties.
//

import Foundation

public struct GameEngine: Sendable {

    public init() {}

    // MARK: - Role Assignment

    /// Assigns roles and words to players for a new round.
    /// - Parameters:
    ///   - players: Participating players (minimum 3).
    ///   - pair: Word pair for this round.
    ///   - language: Language for word localisation.
    ///   - includeMrWhite: Whether to include the Mr. White role (requires ≥ 4 players).
    /// - Returns: A fully populated `GameAssignment`.
    public func assign(
        players: [Player],
        pair: WordPair,
        language: AppLanguage,
        includeMrWhite: Bool
    ) -> GameAssignment {
        precondition(
            players.count >= 3,
            "GameEngine.assign requires at least 3 players."
        )

        let civilian = pair.civilian.localized(for: language)
        let undercover = pair.undercover.localized(for: language)

        var shuffled = players.indices.shuffled()

        let undercoverIdx = shuffled.removeFirst()

        let mrWhiteIdx: Int? = (
            includeMrWhite && players.count >= 4
        )
            ? shuffled.removeFirst()
            : nil

        var words: [UUID: String] = [:]
        var roles: [UUID: PlayerRole] = [:]

        for (idx, player) in players.enumerated() {
            switch idx {
            case undercoverIdx:
                words[player.id] = undercover
                roles[player.id] = .undercover

            case mrWhiteIdx:
                words[player.id] = ""
                roles[player.id] = .mrWhite

            default:
                words[player.id] = civilian
                roles[player.id] = .civilian
            }
        }

        return GameAssignment(
            wordsByPlayer: words,
            rolesByPlayer: roles,
            civilianWord: civilian,
            undercoverWord: undercover,
            undercoverPlayerID: players[undercoverIdx].id,
            mrWhitePlayerID: mrWhiteIdx.map { players[$0].id }
        )
    }

    public func evaluateBoard(
        alivePlayers: [Player],
        rolesByPlayer: [UUID: PlayerRole]
    ) -> (
        aliveCivilians: Int,
        aliveUndercover: Int,
        aliveMrWhite: Int
    ) {
        var civilians = 0
        var undercover = 0
        var mrWhite = 0

        for player in alivePlayers {
            switch rolesByPlayer[player.id] {
            case .civilian:
                civilians += 1

            case .undercover:
                undercover += 1

            case .mrWhite:
                mrWhite += 1

            case nil:
                break
            }
        }

        return (
            aliveCivilians: civilians,
            aliveUndercover: undercover,
            aliveMrWhite: mrWhite
        )
    }

    public func evaluateMrWhiteGuess(
        _ guess: String,
        civilianWord: String
    ) -> Bool {
        NormalizationUtility.normalize(guess)
            == NormalizationUtility.normalize(civilianWord)
    }
}
