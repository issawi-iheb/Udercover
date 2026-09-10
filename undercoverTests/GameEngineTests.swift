//
//  GameEngineTests.swift
//  undercoverTests
//
//
//  GameEngineTests.swift
//  undercoverTests
//

import Testing
@testable import undercover
internal import Foundation

struct GameEngineTests {

    // MARK: - Role Assignment

    @Test func assign_threePlayers_noMrWhite() {
        // Given: Three players
        let playerA = Player(id: UUID(), name: "Alice")
        let playerB = Player(id: UUID(), name: "Bob")
        let playerC = Player(id: UUID(), name: "Charlie")
        let players = [playerA, playerB, playerC]

        // And: A word pair
        let pair = WordPair(
            civilian: LocalizedWord(values: ["en": "cat"]),
            undercover: LocalizedWord(values: ["en": "dog"]),
            topic: "animals",
            similarity: 0.5
        )

        // When: Assigning roles without Mr. White
        let engine = GameEngine()
        let assignment = engine.assign(
            players: players,
            pair: pair,
            language: .english,
            includeMrWhite: false
        )

        // Then: Should have one undercover, one civilian, and no Mr. White
        #expect(assignment.rolesByPlayer.count == 3)
        #expect(assignment.rolesByPlayer.values.filter { $0 == .undercover }.count == 1)
        #expect(assignment.rolesByPlayer.values.filter { $0 == .civilian }.count == 2)
        #expect(assignment.rolesByPlayer.values.filter { $0 == .mrWhite }.count == 0)

        // And: Should have correct word assignments
        #expect(assignment.wordsByPlayer.values.filter { $0 == "cat" }.count == 2)
        #expect(assignment.wordsByPlayer.values.filter { $0 == "dog" }.count == 1)

        // And: Should have correct IDs
        #expect(assignment.undercoverPlayerID != UUID())
        #expect(assignment.mrWhitePlayerID == nil)
    }

    @Test func assign_fourPlayers_withMrWhite() {
        // Given: Four players
        let playerA = Player(id: UUID(), name: "Alice")
        let playerB = Player(id: UUID(), name: "Bob")
        let playerC = Player(id: UUID(), name: "Charlie")
        let playerD = Player(id: UUID(), name: "David")
        let players = [playerA, playerB, playerC, playerD]

        // And: A word pair
        let pair = WordPair(
            civilian: LocalizedWord(values: ["en": "cat"]),
            undercover: LocalizedWord(values: ["en": "dog"]),
            topic: "animals",
            similarity: 0.5
        )

        // When: Assigning roles with Mr. White
        let engine = GameEngine()
        let assignment = engine.assign(
            players: players,
            pair: pair,
            language: .english,
            includeMrWhite: true
        )

        // Then: Should have one undercover, one Mr. White, and two civilians
        #expect(assignment.rolesByPlayer.count == 4)
        #expect(assignment.rolesByPlayer.values.filter { $0 == .undercover }.count == 1)
        #expect(assignment.rolesByPlayer.values.filter { $0 == .mrWhite }.count == 1)
        #expect(assignment.rolesByPlayer.values.filter { $0 == .civilian }.count == 2)

        // And: Should have correct word assignments
        #expect(assignment.wordsByPlayer.values.filter { $0 == "cat" }.count == 2)
        #expect(assignment.wordsByPlayer.values.filter { $0 == "dog" }.count == 1)
        #expect(assignment.wordsByPlayer.values.filter { $0 == "" }.count == 1) // Mr. White gets empty string

        // And: Should have correct IDs
        #expect(assignment.undercoverPlayerID != UUID())
        #expect(assignment.mrWhitePlayerID != nil)
    }
    
    @Test
    func assign_threePlayers_includeMrWhite_ignoresMrWhite() {
        let players = [
            Player(id: UUID(), name: "Alice"),
            Player(id: UUID(), name: "Bob"),
            Player(id: UUID(), name: "Charlie")
        ]

        let pair = WordPair(
            civilian: LocalizedWord(values: ["en": "cat"]),
            undercover: LocalizedWord(values: ["en": "dog"]),
            topic: "animals",
            similarity: 0.5
        )

        let engine = GameEngine()

        let assignment = engine.assign(
            players: players,
            pair: pair,
            language: .english,
            includeMrWhite: true
        )

        #expect(
            assignment.rolesByPlayer.values.filter { $0 == .civilian }.count == 2
        )

        #expect(
            assignment.rolesByPlayer.values.filter { $0 == .undercover }.count == 1
        )

        #expect(
            assignment.rolesByPlayer.values.filter { $0 == .mrWhite }.count == 0
        )

        #expect(assignment.mrWhitePlayerID == nil)
    }
    
    @Test
    func assign_usesRequestedLanguage() {
        let players = [
            Player(id: UUID(), name: "Alice"),
            Player(id: UUID(), name: "Bob"),
            Player(id: UUID(), name: "Charlie")
        ]

        let pair = WordPair(
            civilian: LocalizedWord(
                values: [
                    "en": "cat",
                    "fr": "chat"
                ]
            ),
            undercover: LocalizedWord(
                values: [
                    "en": "dog",
                    "fr": "chien"
                ]
            ),
            topic: "animals",
            similarity: 0.5
        )

        let assignment = GameEngine().assign(
            players: players,
            pair: pair,
            language: .french,
            includeMrWhite: false
        )

        #expect(assignment.civilianWord == "chat")
        #expect(assignment.undercoverWord == "chien")

        #expect(
            assignment.wordsByPlayer.values.filter { $0 == "chat" }.count == 2
        )

        #expect(
            assignment.wordsByPlayer.values.filter { $0 == "chien" }.count == 1
        )
    }

    // MARK: - Win Condition Evaluation

    @Test func evaluateBoard_allCiviliansAlive() {
        // Given: Three alive civilian players
        let playerA = Player(id: UUID(), name: "Alice")
        let playerB = Player(id: UUID(), name: "Bob")
        let playerC = Player(id: UUID(), name: "Charlie")
        let alivePlayers = [playerA, playerB, playerC]

        // And: Role assignments
        let rolesByPlayer: [UUID: PlayerRole] = [
            playerA.id: .civilian,
            playerB.id: .civilian,
            playerC.id: .civilian
        ]

        // When: Evaluating the board
        let engine = GameEngine()
        let result = engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )

        // Then: Should show 3 civilians, 0 undercover, 0 Mr. White
        #expect(result.aliveCivilians == 3)
        #expect(result.aliveUndercover == 0)
        #expect(result.aliveMrWhite == 0)
    }

    @Test func evaluateBoard_mixedRoles() {
        // Given: Five alive players with mixed roles
        let playerA = Player(id: UUID(), name: "Alice")
        let playerB = Player(id: UUID(), name: "Bob")
        let playerC = Player(id: UUID(), name: "Charlie")
        let playerD = Player(id: UUID(), name: "David")
        let playerE = Player(id: UUID(), name: "Eve")
        let alivePlayers = [playerA, playerB, playerC, playerD, playerE]

        // And: Role assignments
        let rolesByPlayer: [UUID: PlayerRole] = [
            playerA.id: .civilian,
            playerB.id: .civilian,
            playerC.id: .undercover,
            playerD.id: .mrWhite,
            playerE.id: .civilian
        ]

        // When: Evaluating the board
        let engine = GameEngine()
        let result = engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )

        // Then: Should show correct counts
        #expect(result.aliveCivilians == 3)
        #expect(result.aliveUndercover == 1)
        #expect(result.aliveMrWhite == 1)
    }

    @Test func evaluateBoard_playersWithNoRoleAreIgnored() {
        // Given: Three players, but only two have assigned roles
        let playerA = Player(id: UUID(), name: "Alice")
        let playerB = Player(id: UUID(), name: "Bob")
        let playerC = Player(id: UUID(), name: "Charlie")
        let alivePlayers = [playerA, playerB, playerC]

        // And: Role assignments (playerC has no role)
        let rolesByPlayer: [UUID: PlayerRole] = [
            playerA.id: .civilian,
            playerB.id: .undercover
            // playerC.id: nil (not present in dictionary)
        ]

        // When: Evaluating the board
        let engine = GameEngine()
        let result = engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )

        // Then: Should only count players with roles
        #expect(result.aliveCivilians == 1)
        #expect(result.aliveUndercover == 1)
        #expect(result.aliveMrWhite == 0)
    }

    // MARK: - Mr. White Guess Evaluation

    @Test func evaluateMrWhiteGuess_correctGuess() {
        // Given: GameEngine
        let engine = GameEngine()

        // When: Evaluating a correct guess
        let result = engine.evaluateMrWhiteGuess(
            "  CAT  ", // guess with whitespace
            civilianWord: "cat"      // civilian word
        )

        // Then: Should return true
        #expect(result == true)
    }

    @Test func evaluateMrWhiteGuess_caseInsensitive() {
        // Given: GameEngine
        let engine = GameEngine()

        // When: Evaluating a guess with different case
        let result = engine.evaluateMrWhiteGuess(
            "Cat",     // guess
            civilianWord: "cAt"      // civilian word
        )

        // Then: Should return true
        #expect(result == true)
    }

    @Test func evaluateMrWhiteGuess_incorrectGuess() {
        // Given: GameEngine
        let engine = GameEngine()

        // When: Evaluating an incorrect guess
        let result = engine.evaluateMrWhiteGuess(
            "dog",     // guess
            civilianWord: "cat"      // civilian word
        )

        // Then: Should return false
        #expect(result == false)
    }

    @Test func evaluateMrWhiteGuess_whitespaceHandling() {
        // Given: GameEngine
        let engine = GameEngine()

        // When: Evaluating guesses with various whitespace
        let result1 = engine.evaluateMrWhiteGuess(
            "  cat  ", // spaces
            civilianWord: "cat"
        )
        let result2 = engine.evaluateMrWhiteGuess(
            "\tcat\n", // tab and newline
            civilianWord: "cat"
        )
        let result3 = engine.evaluateMrWhiteGuess(
            "cat",     // no whitespace
            civilianWord: "  cat  "  // whitespace on civilian word
        )

        // Then: All should return true
        #expect(result1 == true)
        #expect(result2 == true)
        #expect(result3 == true)
    }
}
