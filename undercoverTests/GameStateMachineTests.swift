//
//  GameStateMachineTests.swift
//  undercoverTests
//

//
//  GameStateMachineTests.swift
//  undercoverTests
//

//
//  GameStateMachineTests.swift
//  undercoverTests
//

import Testing
@testable import undercover

struct GameStateMachineTests {

    // MARK: - Scenario 1

    @Test
    func test_scenario1_undercoverElimination_1C_1U_1MW() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .undercover,
            aliveCivilians: 1,
            aliveUndercover: 0,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .mrWhiteGuess(round: 1))
    }

    @Test
    func test_scenario1_civilianElimination_1C_1U_1MW() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .civilian,
            aliveCivilians: 0,
            aliveUndercover: 1,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .mrWhiteGuess(round: 1))
    }

    // MARK: - Scenario 2: Mr. White eliminated

    @Test
    func test_scenario2_mrWhiteEliminated_1C_1U_1MW_wrongGuess() {
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 1,
            aliveUndercover: 1,
            round: 1
        ))

        // 1 Undercover >= 1 Civilian → Undercover wins.
        #expect(fsm.state == .results(.undercoverWins))
    }

    @Test
    func test_scenario2_mrWhiteEliminated_1C_1U_1MW_correctGuess() {
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: true,
            aliveCivilians: 1,
            aliveUndercover: 1,
            round: 1
        ))

        #expect(fsm.state == .results(.mrWhiteWins))
    }

    // MARK: - Scenario 3

    @Test
    func test_scenario3a_undercoverEliminated_2C_1U_1MW() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .undercover,
            aliveCivilians: 2,
            aliveUndercover: 0,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))
    }

    @Test
    func test_scenario3b_civilianEliminated_1C_1U_1MW_continuesDiscussion() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))

        _ = fsm.handle(.votingFinished(
            eliminated: .civilian,
            aliveCivilians: 1,
            aliveUndercover: 1,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))
    }
    // MARK: - Scenario 4

    @Test
    func test_scenario4_mrWhiteEliminated_2C_1U_1MW_wrongGuess_thenUndercoverEliminated() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        // Eliminate Mr. White.
        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .mrWhite,
            aliveCivilians: 2,
            aliveUndercover: 1,
            aliveMrWhite: 0,
            round: 1
        ))

        #expect(fsm.state == .mrWhiteGuess(round: 1))

        // Mr. White guesses incorrectly.
        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 2,
            aliveUndercover: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))

        // Next round: eliminate Undercover.
        _ = fsm.handle(.discussionEnded(round: 2))
        _ = fsm.handle(.votingFinished(
            eliminated: .undercover,
            aliveCivilians: 2,
            aliveUndercover: 0,
            aliveMrWhite: 0,
            round: 2
        ))

        #expect(fsm.state == .results(.civiliansWin))
    }

    // MARK: - Scenario 5

    @Test
    func test_scenario5_civilianEliminated_1C_2U() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .civilian,
            aliveCivilians: 0,
            aliveUndercover: 2,
            aliveMrWhite: 0,
            round: 1
        ))

        #expect(fsm.state == .results(.undercoverWins))
    }

    // MARK: - Scenario 6

    @Test
    func test_scenario6_civilianParity_2C_1U() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .civilian,
            aliveCivilians: 1,
            aliveUndercover: 1,
            aliveMrWhite: 0,
            round: 1
        ))

        // 1 Undercover >= 1 Civilian → Undercover wins.
        #expect(fsm.state == .results(.undercoverWins))
    }

    // MARK: - Scenario 7

    @Test
    func test_scenario7_undercoverEliminated_2C_1U() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .undercover,
            aliveCivilians: 2,
            aliveUndercover: 0,
            aliveMrWhite: 0,
            round: 1
        ))

        #expect(fsm.state == .results(.civiliansWin))
    }

    // MARK: - Scenario 8

    @Test
    func test_scenario8a_undercoverEliminated_3C_1U_1MW() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .undercover,
            aliveCivilians: 3,
            aliveUndercover: 0,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))
    }

    @Test
    func test_scenario8b_ongoingToMrWhiteGuess_3C_1U_1MW() {
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        // 3C + 1MW → eliminate one Civilian.
        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .civilian,
            aliveCivilians: 2,
            aliveUndercover: 0,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))

        // 2C + 1MW → eliminate another Civilian.
        _ = fsm.handle(.discussionEnded(round: 2))
        _ = fsm.handle(.votingFinished(
            eliminated: .civilian,
            aliveCivilians: 1,
            aliveUndercover: 0,
            aliveMrWhite: 1,
            round: 2
        ))

        #expect(fsm.state == .mrWhiteGuess(round: 2))
    }

    // MARK: - Additional Required Tests

    @Test
    func test_undercoverPlusMrWhite_only() {
        // 0C + 1U + 1MW -> should trigger Mr. White guess
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        // Eliminate the civilian to get to 0C + 1U + 1MW
        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .civilian,
            aliveCivilians: 0,
            aliveUndercover: 1,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .mrWhiteGuess(round: 1))
    }

    @Test
    func test_civilianPlusMrWhite_wrongGuess_oneCivilian() {
        // 1C + 0U + 0MW (after Mr. White wrong guess) -> Civilians win
        // Even with only 1 civilian remaining
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 1,
            aliveUndercover: 0,
            round: 1
        ))

        #expect(fsm.state == .results(.civiliansWin))
    }

    @Test
    func test_c_c_u_plus_m_eliminate_undercover_continues() {
        // 2C + 1U + 1MW -> eliminate Undercover -> 2C + 0U + 1MW -> should continue
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .undercover,
            aliveCivilians: 2,
            aliveUndercover: 0,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))
    }

    @Test
    func test_c_plus_m_eliminate_mrwhite_wrongguess_civilians_win() {
        // 1C + 0U + 1MW -> eliminate Mr White -> wrong guess -> Civilians win
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 1,
            aliveUndercover: 0,
            round: 1
        ))

        #expect(fsm.state == .results(.civiliansWin))
    }

    @Test
    func test_c_c_plus_m_eliminate_mrwhite_wrongguess_civilians_win() {
        // 2C + 0U + 1MW -> eliminate Mr White -> wrong guess -> Civilians win
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 2,
            aliveUndercover: 0,
            round: 1
        ))

        #expect(fsm.state == .results(.civiliansWin))
    }

    @Test
    func test_c_plus_u_plus_m_eliminate_mrwhite_wrongguess_undercover_wins() {
        // 1C + 1U + 1MW -> eliminate Mr White -> wrong guess -> Undercover wins
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 1,
            aliveUndercover: 1,
            round: 1
        ))

        #expect(fsm.state == .results(.undercoverWins))
    }

    @Test
    func test_c_c_plus_u_eliminate_undercover_with_mrwhite_continues() {
        // 2C + 1U + 1MW -> eliminate Undercover -> 2C + 0U + 1MW -> should continue (Mr White still alive)
        var fsm = GameStateMachine(initialState: .discussion(round: 1))

        _ = fsm.handle(.discussionEnded(round: 1))
        _ = fsm.handle(.votingFinished(
            eliminated: .undercover,
            aliveCivilians: 2,
            aliveUndercover: 0,
            aliveMrWhite: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))
    }

    // MARK: - Scenario 9: Mr. White wrong guess

    @Test
    func test_scenario9a_wrongGuess_noUndercover() {
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 3,
            aliveUndercover: 0,
            round: 1
        ))

        #expect(fsm.state == .results(.civiliansWin))
    }

    @Test
    func test_scenario9b_wrongGuess_undercoverWins() {
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 1,
            aliveUndercover: 2,
            round: 1
        ))

        #expect(fsm.state == .results(.undercoverWins))
    }

    @Test
    func test_scenario9c_wrongGuess_continues() {
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 2,
            aliveUndercover: 1,
            round: 1
        ))

        #expect(fsm.state == .discussion(round: 2))
    }

    @Test
    func test_scenario9d_wrongGuess_undercoverMajority() {
        var fsm = GameStateMachine(
            initialState: .mrWhiteGuess(round: 1)
        )

        _ = fsm.handle(.mrWhiteGuessResult(
            correct: false,
            aliveCivilians: 1,
            aliveUndercover: 3,
            round: 1
        ))

        #expect(fsm.state == .results(.undercoverWins))
    }
}
