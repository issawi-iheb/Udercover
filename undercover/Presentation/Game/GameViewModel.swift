//
//  GameViewModel.swift
//  undercoverApp
//

import SwiftUI
import Combine

@MainActor
public final class GameViewModel: ObservableObject {
    
    // MARK: - Setup
    
    @Published public var selectedLanguage: AppLanguage = .english {
        didSet {
            prepareWordPairsIfNeeded()
        }
    }
    
    @Published public var selectedDifficulty: PairDifficulty = .medium {
        didSet {
            prepareWordPairsIfNeeded()
        }
    }
    
    @Published public var selectedTopic: String? {
        didSet {
            prepareWordPairsIfNeeded()
        }
    }
    
    @Published public var mrWhiteModeEnabled: Bool = false
    
    
    // MARK: - Players
    
    @Published public var players: [Player] = [] {
        didSet {
            prepareWordPairsIfNeeded()
        }
    }
    
    
    // MARK: - Game State
    
    @Published public private(set) var gameState: GameState = .setup
    
    
    // MARK: - Voting
    
    @Published public var selectedVotePlayerID: UUID?
    
    
    // MARK: - Mr White
    
    @Published public var mrWhiteGuessInput: String = ""
    
    
    // MARK: - Loading
    
    @Published public private(set) var isGeneratingWords = false
    @Published public private(set) var wordGeneratorError: String?
    
    
    // MARK: - Round Data
    
    @Published public private(set) var revealOrder: [UUID] = []
    
    @Published public private(set) var assignments: [UUID:String] = [:]
    
    @Published public private(set) var rolesByPlayer: [UUID:PlayerRole] = [:]
    
    @Published public private(set) var undercoverPlayerID: UUID?
    
    @Published public private(set) var mrWhitePlayerID: UUID?
    
    @Published public private(set) var currentCivilianWord = ""
    
    @Published public private(set) var currentUndercoverWord = ""
    
    
    // MARK: - Timer
    
    @Published public private(set) var timeRemaining = 0
    
    @Published public private(set) var isTimerRunning = false
    
    
    
    // MARK: - Private Infrastructure
    
    private var fsm = GameStateMachine()
    private let engine = GameEngine()
    private let wordPairProvider = WordPairProvider()
    private var timer: Timer?
    
    // MARK: - Derived
    
    @Published
    public var availableTopics: [GameTopic] = []
    
    
    public var alivePlayers: [Player] {
        players.filter { !$0.isEliminated }
    }
    
    
    public var mrWhiteEnabled: Bool {
        mrWhiteModeEnabled && players.count >= 4
    }
    
    
    
    public var currentRevealIndex: Int {
        
        guard case .reveal(let index, _) = gameState else {
            return 0
        }
        
        return index
    }
    
    
    
    public var currentRevealStep: RevealStep {
        
        guard case .reveal(_, let step) = gameState else {
            return .passDevice
        }
        
        return step
    }
    
    
    
    public var currentRound: Int {
        
        switch gameState {
                
            case .discussion(let round):
                return round
                
            case .voting(let round):
                return round
                
            case .mrWhiteGuess(let round):
                return round
                
            default:
                return 1
        }
    }
    
    
    
    public var revealProgress: Double {
        
        guard case .reveal(let index, _) = gameState,
              !revealOrder.isEmpty else {
            return 0
        }
        
        return Double(index + 1) /
        Double(revealOrder.count)
    }
    
    
    
    public var isFinalMrWhiteDuel: Bool {
        
        let board = engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )
        
        return board.aliveCivilians == 0 &&
        board.aliveUndercover == 1 &&
        board.aliveMrWhite == 1
    }
    
    
    
    // MARK: - Player Management
    
    public func addPlayer(name: String) {
        
        let trimmed =
        name.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else {
            return
        }
        
        Haptic.light()
        
        withAnimation(.spring(response: 0.4,
                              dampingFraction: 0.7)) {
            
            players.append(
                Player(name: trimmed)
            )
        }
    }
    
    
    
    public func removePlayer(at offsets: IndexSet) {
        
        withAnimation {
            
            players.remove(atOffsets: offsets)
        }
    }
    
    
    
    // MARK: - Game Lifecycle
    
    
    public func startGame(keepPlayers: Bool = false) async {

        guard players.count >= 3 else {
            return
        }
        isGeneratingWords = true
        
        wordGeneratorError = nil
        if keepPlayers {
            
            players = players.map {
                
                Player(
                    id: $0.id,
                    name: $0.name,
                    isEliminated: false
                )
            }
        }
        if case .results = fsm.state {
            
            fsm.handle(
                .replay(playerCount: players.count)
            )
            
        } else {
            
            fsm.handle(.startLoading)
        }
        syncState()
        
        
        let topic = selectedTopic ?? ""
        
        wordPairProvider.prepareIfNeeded(
            playerCount: players.count,
            topic: topic,
            language: selectedLanguage,
            difficulty: selectedDifficulty
        )
        let pair: WordPair

        do {
            pair = try await wordPairProvider.nextPair(
                playerCount: players.count,
                topic: topic,
                language: selectedLanguage,
                difficulty: selectedDifficulty
            )
        } catch {
            isGeneratingWords = false
            wordGeneratorError = error.localizedDescription

            print("❌ Failed to generate word pair:", error)

            return
        }
        let assignment =
        engine.assign(
            players: players,
            pair: pair,
            language: selectedLanguage,
            includeMrWhite: mrWhiteEnabled
        )
        assignments = assignment.wordsByPlayer
        rolesByPlayer = assignment.rolesByPlayer
        undercoverPlayerID = assignment.undercoverPlayerID
        mrWhitePlayerID = assignment.mrWhitePlayerID
        currentCivilianWord = assignment.civilianWord
        currentUndercoverWord = assignment.undercoverWord
        revealOrder =
        alivePlayers.map(\.id).shuffled()
        isGeneratingWords = false
        fsm.handle(
            .wordsReady(
                playerCount: revealOrder.count
            )
        )
        syncState()
        Haptic.success()
    }
    
    
    public func replay() async {
        
        await startGame(
            keepPlayers: true
        )
    }
    // MARK: - New Game
    
    public func newGame() {
        
        stopTimer()
        
        players = []
        
        assignments = [:]
        
        rolesByPlayer = [:]
        
        undercoverPlayerID = nil
        
        mrWhitePlayerID = nil
        
        currentCivilianWord = ""
        
        currentUndercoverWord = ""
        
        revealOrder = []
        
        mrWhiteGuessInput = ""
        
        selectedVotePlayerID = nil
        wordPairProvider.reset()
        
        fsm.handle(.newGame)
        
        syncState()
    }
    
    
    
    // MARK: - Reveal
    
    
    public func currentRevealingPlayer() -> Player? {
        
        guard case .reveal(let index, _) = gameState,
              index < revealOrder.count else {
            
            return nil
        }
        
        
        return players.first {
            $0.id == revealOrder[index]
        }
    }
    
    
    
    /// Returns player's word.
    /// Mr White receives an empty string.
    
    public func word(for player: Player) -> String {
        
        assignments[player.id] ?? ""
    }

    public func role(for player: Player) -> PlayerRole {
        
        rolesByPlayer[player.id] ?? .civilian
    }
    
    public func revealTapped() {
        
        Haptic.medium()
        
        fsm.handle(.revealTapped)
        
        syncState()
    }

    public func revealNext() {
        
        Haptic.light()
        
        fsm.handle(
            .revealNext(
                totalPlayers: revealOrder.count
            )
        )
        
        syncState()
    }

    
    // MARK: - Timer
    
    
    public func startDiscussionTimer(seconds: Int) {
        
        stopTimer()
        timeRemaining = seconds
        
        isTimerRunning = true
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            
            
            Task { @MainActor [weak self] in
                
                
                guard let self,
                      self.isTimerRunning else {
                    
                    return
                }
                
                
                
                if self.timeRemaining > 0 {
                    
                    
                    self.timeRemaining -= 1
                    
                    
                    if self.timeRemaining <= 10 {
                        
                        Haptic.light()
                    }
                    
                    
                } else {
                    
                    
                    self.stopTimer()
                    
                    self.enterVoting()
                }
            }
        }
    }
    
    
    
    public func stopTimer() {
        
        timer?.invalidate()
        
        timer = nil
        
        isTimerRunning = false
    }
    
    
    
    // MARK: - Voting
    
    
    
    public func enterVoting() {
        
        stopTimer()
        
        selectedVotePlayerID = nil
        
        Haptic.heavy()
        
        
        fsm.handle(
            .discussionEnded(
                round: currentRound
            )
        )
        
        
        syncState()
    }
    
    // MARK: - Skip Voting

    public func skipVoting() {
        
        guard case .discussion(let round) = gameState else {
            print("⚠️ skipVoting ignored \(gameState)")
            return
        }
        
        stopTimer()
        selectedVotePlayerID = nil
        
        Haptic.medium()
        
        fsm.handle(
            .skipVoting(
                round: round
            )
        )
        
        syncState()
        
        // Start a fresh discussion timer for the new round.
        if case .discussion = gameState {
            startDiscussionTimer(
                seconds: Config.discussionTimerSeconds
            )
        }
    }
    
    public func finishVoting() {
        
        
        guard case .voting = gameState else {
            
            print(
                "⚠️ finishVoting ignored \(gameState)"
            )
            
            return
        }
        
        
        
        guard let votedID = selectedVotePlayerID else {
            
            return
        }
        
        
        
        let role =
        rolesByPlayer[votedID] ?? .civilian
        
        
        
        print(
            "🗳️ Eliminated role:",
            role
        )
        
        
        
        eliminate(
            playerID: votedID
        )
        
        
        
        let board =
        engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )
        
        
        
        print(
            "Alive civilians:",
            board.aliveCivilians
        )
        
        print(
            "Alive undercover:",
            board.aliveUndercover
        )
        
        print(
            "Alive MrWhite:",
            board.aliveMrWhite
        )

        fsm.handle(
            .votingFinished(
                eliminated: role,
                aliveCivilians: board.aliveCivilians,
                aliveUndercover: board.aliveUndercover,
                aliveMrWhite: board.aliveMrWhite,
                round: currentRound
            )
        )

        syncState()

        if case .mrWhiteGuess = gameState {
            
            mrWhiteGuessInput = ""
        }

        triggerResultHaptic()
    }

    
    // MARK: - Mr White Guess

    public func submitMrWhiteGuess() {
        
        
        let correct =
        engine.evaluateMrWhiteGuess(
            mrWhiteGuessInput,
            civilianWord: currentCivilianWord
        )
        
        
        
        let board =
        engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )
        
        
        
        print(
            "🃏 Mr White guess:",
            mrWhiteGuessInput
        )
        
        print(
            "Correct:",
            correct
        )

        fsm.handle(
            .mrWhiteGuessResult(
                correct: correct,
                aliveCivilians: board.aliveCivilians,
                aliveUndercover: board.aliveUndercover,
                round: currentRound
            )
        )
        
        
        
        syncState()
        
        if correct {
            
            Haptic.error()
            
        } else {
            
            Haptic.success()
        }
    }

    // MARK: - Queries

    public func undercoverPlayer() -> Player? {
        
        players.first {
            $0.id == undercoverPlayerID
        }
    }
    
    public func mrWhitePlayer() -> Player? {
        
        players.first {
            $0.id == mrWhitePlayerID
        }
    }
    
    // MARK: - Private Helpers

    private func syncState() {
        
        gameState = fsm.state
    }
    

    private func eliminate(playerID: UUID) {
        
        guard let index =
                players.firstIndex(
                    where: {
                        $0.id == playerID
                    }
                )
        else {
            
            return
        }

        Haptic.heavy()
        withAnimation(.spring()) {
            players[index] =
            Player(
                id: players[index].id,
                name: players[index].name,
                isEliminated: true
            )
        }
    }
    
    private func triggerResultHaptic() {
        
        switch gameState {
                
            case .results(.civiliansWin):
                Haptic.success()
            case .results(.undercoverWins),
                  .results(.mrWhiteWins):
                
                Haptic.error()
                
            default: break
        }
    }
    // MARK: - Word Preparation

    private func prepareWordPairsIfNeeded() {
        wordPairProvider.prepareIfNeeded(
            playerCount: players.count,
            topic: selectedTopic,
            language: selectedLanguage,
            difficulty: selectedDifficulty
        )
    }
}
