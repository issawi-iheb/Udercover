//
//  GameViewModel.swift
//  undercoverApp
//
//  Thin @MainActor coordinator. Owns no business logic:
//  - State transitions → GameStateMachine
//  - Role/word assignment → GameEngine
//  - Word fetching → WordGeneratorService
//  - Persistence → PlayedPairStore
//

import SwiftUI
import Combine

// MARK: - Haptics

//enum Haptic {
//    static func light()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
//    static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
//    static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
//    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
//    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
//}

// MARK: - ViewModel

@MainActor
public final class GameViewModel: ObservableObject {

    // MARK: Setup
    @Published public var selectedLanguage:   AppLanguage    = .english
    @Published public var selectedDifficulty: PairDifficulty = .medium
    @Published public var selectedTopic:      String?
    @Published public var mrWhiteModeEnabled: Bool           = false

    // MARK: Players
    @Published public var players: [Player] = []

    // MARK: Game state — read-only outside ViewModel
    @Published public private(set) var gameState: GameState = .setup

    // MARK: Voting
    @Published public var selectedVotePlayerID: UUID? = nil

    // MARK: Mr. White
    @Published public var mrWhiteGuessInput: String = ""

    // MARK: Loading
    @Published public private(set) var isGeneratingWords:  Bool    = false
    @Published public private(set) var wordGeneratorError: String? = nil

    // MARK: Round data — read-only outside ViewModel
    @Published public private(set) var revealOrder:           [UUID]             = []
    @Published public private(set) var assignments:           [UUID: String]     = [:]
    @Published public private(set) var rolesByPlayer:         [UUID: PlayerRole] = [:]
    @Published public private(set) var undercoverPlayerID:    UUID?              = nil
    @Published public private(set) var mrWhitePlayerID:       UUID?              = nil
    @Published public private(set) var currentCivilianWord:   String             = ""
    @Published public private(set) var currentUndercoverWord: String             = ""

    // MARK: Timer
    @Published public private(set) var timeRemaining:  Int  = 0
    @Published public private(set) var isTimerRunning: Bool = false

    // MARK: Private infrastructure
    private var fsm        = GameStateMachine()
    private let engine     = GameEngine()
    private let topicService = TopicService()
    private let pairStore  = PlayedPairStore()
    private var timer:       Timer?

    // Lazy so cache persists across rounds within a session.
    private lazy var generatorService = WordGeneratorService(generators: [
        FoundationModelsWordGenerator(),
        LocalWordGenerator()
    ])

    // MARK: - Derived

    @Published
    public var availableTopics:[GameTopic] = []
    public var alivePlayers:    [Player]  { players.filter { !$0.isEliminated } }
    public var mrWhiteEnabled:  Bool      { mrWhiteModeEnabled && players.count >= 4 }

    public var currentRevealIndex: Int {
        guard case .reveal(let idx, _) = gameState else { return 0 }
        return idx
    }

    public var currentRevealStep: RevealStep {
        guard case .reveal(_, let step) = gameState else { return .passDevice }
        return step
    }

    public var currentRound: Int {
        switch gameState {
        case .discussion(let r):  return r
        case .voting(let r):      return r
        case .mrWhiteGuess(let r): return r
        default:                  return 1
        }
    }

    public var revealProgress: Double {
        guard case .reveal(let idx, _) = gameState, !revealOrder.isEmpty else { return 0 }
        return Double(idx + 1) / Double(revealOrder.count)
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

    // MARK: - Player management

    public func addPlayer(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptic.light()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            players.append(Player(name: trimmed))
        }
    }

    public func removePlayer(at offsets: IndexSet) {
        withAnimation { players.remove(atOffsets: offsets) }
    }

    // MARK: - Game lifecycle
    
    public func loadTopics() async {

        availableTopics = await topicService.topics()

    }

    public func startGame(keepPlayers: Bool = false) async {
        guard players.count >= 3 else { return }

        isGeneratingWords  = true
        wordGeneratorError = nil

        if keepPlayers {
            players = players.map { Player(id: $0.id, name: $0.name, isEliminated: false) }
        }

        //fsm.handle(.startLoading)
        if case .results = fsm.state {
            fsm.handle(.replay(playerCount: players.count))
        } else {
            fsm.handle(.startLoading)
        }
        syncState()

        let topic = selectedTopic ?? ""
        let used  = await pairStore.usedKeys(for: topic)
        let pair  = await resolvePair(topic: topic, excluding: used)

        await pairStore.markPlayed(trackingKey: pair.trackingKey, topic: topic)

        let assignment = engine.assign(
            players:        players,
            pair:           pair,
            language:       selectedLanguage,
            includeMrWhite: mrWhiteEnabled
        )

        assignments           = assignment.wordsByPlayer
        rolesByPlayer         = assignment.rolesByPlayer
        undercoverPlayerID    = assignment.undercoverPlayerID
        mrWhitePlayerID       = assignment.mrWhitePlayerID
        currentCivilianWord   = assignment.civilianWord
        currentUndercoverWord = assignment.undercoverWord
        revealOrder           = alivePlayers.map(\.id).shuffled()
        isGeneratingWords     = false

        fsm.handle(.wordsReady(playerCount: revealOrder.count))
        syncState()
        Haptic.success()
    }

    public func replay()  async { await startGame(keepPlayers: true) }

    public func newGame() {
        stopTimer()
        players               = []
        assignments           = [:]
        rolesByPlayer         = [:]
        undercoverPlayerID    = nil
        mrWhitePlayerID       = nil
        currentCivilianWord   = ""
        currentUndercoverWord = ""
        revealOrder           = []
        mrWhiteGuessInput     = ""
        selectedVotePlayerID  = nil
        fsm.handle(.newGame)
        syncState()
    }

    // MARK: - Reveal

    public func currentRevealingPlayer() -> Player? {
        guard case .reveal(let idx, _) = gameState, idx < revealOrder.count else { return nil }
        return players.first { $0.id == revealOrder[idx] }
    }

    /// Returns the word for a player. Empty string for Mr. White (shown as blank in UI).
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
        fsm.handle(.revealNext(totalPlayers: revealOrder.count))
        syncState()
        if case .discussion = gameState { startDiscussionTimer(seconds: Config.discussionTimerSeconds) }
    }

    // MARK: - Timer

    public func startDiscussionTimer(seconds: Int) {
        stopTimer()
        timeRemaining  = seconds
        isTimerRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isTimerRunning else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    if self.timeRemaining <= 10 { Haptic.light() }
                } else {
                    self.stopTimer()
                    self.enterVoting()
                }
            }
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer          = nil
        isTimerRunning = false
    }

    // MARK: - Voting

    public func enterVoting() {
        stopTimer()
        selectedVotePlayerID = nil
        Haptic.heavy()
        fsm.handle(.discussionEnded(round: currentRound))
        syncState()
    }

    public func finishVoting() {
        guard case .voting = gameState else {
            print("⚠️ finishVoting ignored — current state: \(gameState)")
            return
        }

        guard let votedID = selectedVotePlayerID else {
            return
        }

        let role = rolesByPlayer[votedID] ?? .civilian

        print("🗳️ Voted player: \(votedID)")
        print("🗳️ Voted role: \(role)")

        eliminate(playerID: votedID)

        let board = engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )

        print("🗳️ Alive civilians: \(board.aliveCivilians)")
        print("🗳️ Alive undercover: \(board.aliveUndercover)")
        print("🗳️ Alive Mr. White: \(board.aliveMrWhite)")

        fsm.handle(.votingFinished(
            eliminated: role,
            aliveCivilians: board.aliveCivilians,
            aliveUndercover: board.aliveUndercover,
            aliveMrWhite: board.aliveMrWhite,
            round: currentRound
        ))

        syncState()

        print("🎮 New game state: \(gameState)")

        triggerResultHaptic()

        if case .mrWhiteGuess = gameState {
            mrWhiteGuessInput = ""
        }
    }

    // MARK: - Mr. White guess

    public func submitMrWhiteGuess() {
        let correct = engine.evaluateMrWhiteGuess(
            mrWhiteGuessInput,
            civilianWord: currentCivilianWord
        )

        let board = engine.evaluateBoard(
            alivePlayers: alivePlayers,
            rolesByPlayer: rolesByPlayer
        )

        print("🃏 Mr. White guess: \(mrWhiteGuessInput)")
        print("🃏 Correct: \(correct)")
        print("🃏 Alive civilians: \(board.aliveCivilians)")
        print("🃏 Alive undercover: \(board.aliveUndercover)")

        fsm.handle(
            .mrWhiteGuessResult(
                correct: correct,
                aliveCivilians: board.aliveCivilians,
                aliveUndercover: board.aliveUndercover,
                round: currentRound
            )
        )

        syncState()

        print("🎮 New game state: \(gameState)")

        if correct {
            Haptic.error()
        } else {
            Haptic.success()
        }
    }

    // MARK: - Queries

    public func undercoverPlayer() -> Player? { players.first { $0.id == undercoverPlayerID } }
    public func mrWhitePlayer()    -> Player? { players.first { $0.id == mrWhitePlayerID } }

    // MARK: - Private

    private func syncState() { gameState = fsm.state }

    private func eliminate(playerID: UUID) {
        guard let i = players.firstIndex(where: { $0.id == playerID }) else { return }
        Haptic.heavy()
        withAnimation(.spring()) {
            players[i] = Player(id: players[i].id, name: players[i].name, isEliminated: true)
        }
    }

    private func triggerResultHaptic() {
        switch gameState {
        case .results(.civiliansWin):  Haptic.success()
        case .results(.undercoverWins), .results(.mrWhiteWins): Haptic.error()
        default: break
        }
    }

    private func resolvePair(topic: String, excluding: Set<String>) async -> WordPair {
        do {
            return try await generatorService.randomPair(
                topic:      topic,
                language:   selectedLanguage,
                difficulty: selectedDifficulty,
                excluding:  excluding
            )
        } catch {
            wordGeneratorError = error.localizedDescription
            return fallbackPair()
        }
    }

    private func fallbackPair() -> WordPair {
        let options: [WordPair] = [
            WordPair(
                civilian:   LocalizedWord(values: ["en":"cat",  "ar":"قطة","fr":"chat",  "es":"gato", "tn":"قطوس"]),
                undercover: LocalizedWord(values: ["en":"tiger","ar":"نمر","fr":"tigre","es":"tigre","tn":"نمر"]),
                topic: "animals", similarity: 0.62
            ),
            WordPair(
                civilian:   LocalizedWord(values: ["en":"dog", "ar":"كلب","fr":"chien","es":"perro","tn":"كلب"]),
                undercover: LocalizedWord(values: ["en":"wolf","ar":"ذئب","fr":"loup", "es":"lobo", "tn":"ذيب"]),
                topic: "animals", similarity: 0.60
            )
        ]
        return options.randomElement()!
    }
}

