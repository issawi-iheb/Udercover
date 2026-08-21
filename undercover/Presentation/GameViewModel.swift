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
    
    private let topicService = TopicService()
    
    private let pairStore = PlayedPairStore()
    
    private var timer: Timer?
    
    
    
    // MARK: - Word Cache
    
    private var preparedWordPairs: [WordPair] = []
    
    private var preparedConfiguration: WordBatchConfiguration?
    
    private var preparationTask: Task<Void, Never>?
    
    private let preparationBatchSize = 3
    
    
    private struct WordBatchConfiguration: Equatable {
        
        let topic: String
        
        let language: AppLanguage
        
        let difficulty: PairDifficulty
    }
    
    
    
    // MARK: - Generator
    
    private lazy var generatorService = WordGeneratorService(
        generators: [
            LocalWordGenerator(),
            FoundationModelsWordGenerator()
        ]
    )
    
    
    
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
    
    
    public func startGame(
        keepPlayers: Bool = false
    ) async {
        
        
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
        
        let used =
        await pairStore.usedKeys(
            for: topic
        )
        
        
        let pair =
        await resolvePair(
            topic: topic,
            excluding: used
        )
        
        
        await pairStore.markPlayed(
            trackingKey: pair.trackingKey,
            topic: topic
        )
        
        
        
        let assignment =
        engine.assign(
            players: players,
            pair: pair,
            language: selectedLanguage,
            includeMrWhite: mrWhiteEnabled
        )
        
        
        
        assignments =
        assignment.wordsByPlayer
        
        
        rolesByPlayer =
        assignment.rolesByPlayer
        
        
        undercoverPlayerID =
        assignment.undercoverPlayerID
        
        
        mrWhitePlayerID =
        assignment.mrWhitePlayerID
        
        
        currentCivilianWord =
        assignment.civilianWord
        
        
        currentUndercoverWord =
        assignment.undercoverWord
        
        
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
        
        
        preparedWordPairs.removeAll()
        
        preparedConfiguration = nil
        
        preparationTask?.cancel()
        
        preparationTask = nil
        
        
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
        
        
        
        if case .discussion = gameState {
            
            startDiscussionTimer(
                seconds: Config.discussionTimerSeconds
            )
        }
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
                
                
                
            default:
                
                break
        }
    }
    // MARK: - Word Preparation


    /// Prepares word pairs in background.
    /// Keeps a small cache ready before the game starts.
    private func prepareWordPairsIfNeeded() {


        guard players.count >= 3,
              let topic = selectedTopic,
              !topic.isEmpty
        else {

            preparationTask?.cancel()

            preparationTask = nil

            preparedWordPairs.removeAll()

            preparedConfiguration = nil

            return
        }



        let configuration =
        WordBatchConfiguration(
            topic: topic,
            language: selectedLanguage,
            difficulty: selectedDifficulty
        )



        // Already enough cached pairs
        if preparedConfiguration == configuration,
           preparedWordPairs.count >= preparationBatchSize {

            return
        }




        // Configuration changed
        if preparedConfiguration != configuration {


            preparationTask?.cancel()

            preparationTask = nil


            preparedWordPairs.removeAll()


            preparedConfiguration = configuration
        }




        // Already generating
        guard preparationTask == nil else {

            return
        }




        preparationTask =
        Task { [weak self] in


            guard let self else {

                return
            }



            var excluded =
            await pairStore.usedKeys(
                for: configuration.topic
            )




            while !Task.isCancelled {



                let currentCount =
                await MainActor.run {

                    self.preparedWordPairs.count
                }



                if currentCount >= self.preparationBatchSize {

                    break
                }




                do {



                    let pair =
                    try await generatorService.randomPair(
                        topic: configuration.topic,
                        language: configuration.language,
                        difficulty: configuration.difficulty,

                        // IMPORTANT:
                        // prevents Apple Intelligence context overflow
                        excluding: Set(
                            excluded.suffix(20)
                        )
                    )




                    excluded.insert(
                        pair.trackingKey
                    )




                    await MainActor.run {



                        guard self.preparedConfiguration == configuration
                        else {

                            return
                        }



                        self.preparedWordPairs.append(
                            pair
                        )
                    }




                } catch {


                    print(
                        "⚠️ Word preparation stopped:",
                        error.localizedDescription
                    )


                    break
                }
            }





            await MainActor.run {


                self.preparationTask = nil
            }
        }
    }





    // MARK: - Resolve Word Pair



    private func resolvePair(
        topic: String,
        excluding: Set<String>
    ) async -> WordPair {



        // Use prepared cache first

        if let configuration = preparedConfiguration,

           configuration.topic == topic,

           configuration.language == selectedLanguage,

           configuration.difficulty == selectedDifficulty {



            if let index =
                preparedWordPairs.firstIndex(
                    where: {
                        !excluding.contains(
                            $0.trackingKey
                        )
                    }
                ) {



                let pair =
                preparedWordPairs.remove(
                    at: index
                )



                // refill asynchronously

                prepareWordPairsIfNeeded()



                return pair
            }
        }





        // Normal generation fallback

        do {


            return try await generatorService.randomPair(

                topic: topic,

                language: selectedLanguage,

                difficulty: selectedDifficulty,

                // IMPORTANT:
                // avoids huge prompts
                excluding: Set(
                    excluding.suffix(20)
                )
            )



        } catch {



            wordGeneratorError =
            error.localizedDescription



            return fallbackPair()
        }
    }





    // MARK: - Emergency fallback



    private func fallbackPair() -> WordPair {


        let options: [WordPair] = [


            WordPair(

                civilian:
                    LocalizedWord(
                        values: [
                            "en":"cat",
                            "fr":"chat",
                            "ar":"قطة",
                            "es":"gato",
                            "tn":"قطوس"
                        ]
                    ),


                undercover:
                    LocalizedWord(
                        values: [
                            "en":"tiger",
                            "fr":"tigre",
                            "ar":"نمر",
                            "es":"tigre",
                            "tn":"نمر"
                        ]
                    ),


                topic: "animals",

                similarity: 0.62
            ),




            WordPair(

                civilian:
                    LocalizedWord(
                        values: [
                            "en":"dog",
                            "fr":"chien",
                            "ar":"كلب",
                            "es":"perro",
                            "tn":"كلب"
                        ]
                    ),


                undercover:
                    LocalizedWord(
                        values: [
                            "en":"wolf",
                            "fr":"loup",
                            "ar":"ذئب",
                            "es":"lobo",
                            "tn":"ذيب"
                        ]
                    ),


                topic: "animals",

                similarity: 0.60
            )
        ]



        return options.randomElement()!
    }
}
