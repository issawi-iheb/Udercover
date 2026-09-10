# Test Coverage Analysis for Undercover Game

## 1. Executive Summary

The test coverage in this codebase is highly uneven. The GameStateMachine has comprehensive unit tests covering various game scenarios and edge cases, representing good behavioral testing of this core component. However, virtually all other components lack any form of automated testing.

The existing tests follow good practices for the GameStateMachine:
- They test state transitions based on events
- They cover various win conditions and edge cases
- They use the actual implementation without mocks (appropriate for this pure value-type FSM)
- They test both typical scenarios and edge cases

However, the absence of tests for other critical components creates significant risk:
- No validation of data loading/persistence layers
- No testing of networking/AI integration points
- No verification of business logic in ViewModels
- No testing of async/await concurrency patterns
- No testing of SwiftUI integration points

The architecture is generally testable (good use of dependency injection, pure functions, protocol-oriented design), but the lack of tests means regressions could easily go undetected.

## 2. Current Test Coverage

| Component | Behavior | Existing Test? | Coverage | Missing Scenario | Priority |
|-----------|----------|----------------|----------|------------------|----------|
| GameStateMachine | Initial state (.setup) | ✅ | Good | — | — |
| GameStateMachine | Transition to loadingWords | ✅ | Good | — | — |
| GameStateMachine | Reveal phase transitions | ✅ | Good | — | — |
| GameStateMachine | Discussion phase transitions | ✅ | Good | — | — |
| GameStateMachine | Voting phase transitions | ✅ | Good | — | — |
| GameStateMachine | Mr. White guess phase | ✅ | Good | — | — |
| GameStateMachine | Results phase (all win conditions) | ✅ | Good | — | — |
| GameStateMachine | Replay functionality | ✅ | Good | — | — |
| GameStateMachine | New game reset | ✅ | Good | — | — |
| GameStateMachine | Complex elimination scenarios | ✅ | Good | — | — |
| AppState | Initial state (empty topics, not ready) | ❌ | Missing | Initial state verification | 🔴 High |
| AppState | Bootstrap success (loading topics) | ❌ | Missing | Successful topic loading | 🔴 High |
| AppState | Bootstrap failure handling | ❌ | Missing | Error state when topics fail to load | 🔴 High |
| AppState | Idempotent bootstrap (multiple calls) | ❌ | Missing | Bootstrap called multiple times | 🟠 Medium |
| TopicService | Initial state (empty cache) | ❌ | Missing | Initial cache state | 🔴 High |
| TopicService | Local topics only (no AI) | ❌ | Missing | Topics from local repository only | 🔴 High |
| TopicService | AI topics only (no local) | ❌ | Missing | Topics from AI provider only | 🔴 High |
| TopicService | Merged topics (local + AI) | ❌ | Missing | Combination and deduplication | 🔴 High |
| TopicService | Caching behavior (second call returns cached) | ❌ | Missing | Cache hit behavior | 🔴 High |
| TopicService | Normalization of topic IDs | ❌ | Missing | ID normalization logic | 🟠 Medium |
| TopicService | Sorting of merged topics | ❌ | Missing | Alphabetical sorting of topics | 🟠 Medium |
| WordRepository | Initialization from JSON | ❌ | Missing | Successful loading of words.json | 🔴 High |
| WordRepository | Handling missing/corrupted JSON | ❌ | Missing | Graceful degradation when JSON fails | 🔴 High |
| WordRepository | Topics list generation | ❌ | Missing | Correct extraction of topic keys | 🟠 Medium |
| WordRepository | Filtering by difficulty | ❌ | Missing | Difficulty-based filtering | 🔴 High |
| WordRepository | Language localization filtering | ❌ | Missing | Language-specific word filtering | 🔴 High |
| WordRepository | Exclusion set filtering | ❌ | Missing | Proper exclusion of used concepts | 🔴 High |
| WordRepository | Random pair selection | ❌ | Missing | Uniform random distribution | 🟠 Medium |
| WordRepository | All pairs for topic (stats) | ❌ | Missing | Retrieval of all pairs for a topic | 🟠 Low |
| GameEngine | Role assignment correctness | ❌ | Missing | Proper distribution of roles | 🔴 High |
| GameEngine | Role assignment with Mr. White | ❌ | Missing | Mr. White role inclusion logic | 🔴 High |
| GameEngine | Role assignment without Mr. White | ❌ | Missing | Games with < 4 players | 🔴 High |
| GameEngine | Board evaluation (counting roles) | ❌ | Missing | Accurate counting of alive players by role | 🔴 High |
| GameEngine | Mr. White guess evaluation | ❌ | Missing | Case-insensitive, trimmed comparison | 🔴 High |
| GameViewModel | Player management (add/remove) | ❌ | Missing | Adding and removing players | 🔴 High |
| GameViewModel | Game start flow | ❌ | Missing | Complete game initialization | 🔴 High |
| GameViewModel | Word pair generation integration | ❌ | Missing | Interaction with WordPairProvider | 🔴 High |
| GameViewModel | Role assignment and distribution | ❌ | Missing | Correct assignment of roles/words | 🔴 High |
| GameViewModel | Reveal phase handling | ❌ | Missing | Tapping to reveal words | 🔴 High |
| GameViewModel | Discussion timer | ❌ | Missing | Timer countdown and auto-advance | 🔴 High |
| GameViewModel | Voting logic | ❌ | Missing | Player selection and vote submission | 🔴 High |
| GameViewModel | Elimination process | ❌ | Missing | Marking players as eliminated | 🔴 High |
| GameViewModel | Mr. White guessing | ❌ | Missing | Submitting and validating guesses | 🔴 High |
| GameViewModel | Game state synchronization | ❌ | Missing | Keeping ViewModel in sync with FSM | 🔴 High |
| GameViewModel | Replay functionality | ❌ | Missing | Starting new game with same players | 🔴 High |
| GameViewModel | New game reset | ❌ | Missing | Complete reset to initial state | 🔴 High |
| GameViewModel | Error handling (word generation failures) | ❌ | Missing | Graceful handling of generation errors | 🔴 High |
| GameViewModel | Topic preparation and caching | ❌ | Missing | Pre-loading word pairs for performance | 🔴 High |
| WordPairProvider | Initial Local pair generation | ❌ | Missing | First pair from local generator | 🔴 High |
| WordPairProvider | LLM background refill | ❌ | Missing | Background AI pair generation | 🔴 High |
| WordPairProvider | Cache consumption (FIFO) | ❌ | Missing | Proper removal of used pairs | 🔴 High |
| WordPairProvider | Cache threshold refill triggering | ❌ | Missing | Refill when cache <= threshold | 🔴 High |
| WordPairProvider | Exclusion handling (used concepts) | ❌ | Missing | Avoiding recently used pairs | 🔴 High |
| WordPairProvider | Cache conflict detection | ❌ | Missing | Avoiding conceptual duplicates in cache | 🔴 High |
| WordPairProvider | Configuration change handling | ❌ | Missing | Reset when topic/language/difficulty changes | 🔴 High |
| WordPairProvider | Concurrent access safety | ❌ | Missing | Thread-safe cache operations | 🔴 High |
| WordPairProvider | Error handling (generation failures) | ❌ | Missing | Fallback behavior when generators fail | 🔴 High |
| WordGeneratorService | Generator selection (Local first) | ❌ | Missing | Priority-based generator selection | 🔴 High |
| WordGeneratorService | Generator availability checking | ❌ | Missing | Proper availability checks | 🔴 High |
| WordGeneratorService | Error propagation | ❌ | Missing | Correct error handling from generators | 🔴 High |
| LocalWordGenerator | Repository integration | ❌ | Missing | Correct use of WordRepository | 🔴 High |
| LocalWordGenerator | Exclusion respect | ❌ | Missing | Proper application of exclusion sets | 🔴 High |
| LocalWordGenerator | Fallback behavior (no pairs) | ❌ | Missing | Throwing error when no pairs available | 🔴 High |
| FoundationModelsWordGenerator | Availability checking (iOS 26+) | ❌ | Missing | Correct iOS version checking | 🔴 High |
| FoundationModelsWordGenerator | Language model availability | ❌ | Missing | Checking FoundationModels availability | 🔴 High |
| FoundationModelsWordGenerator | Prompt construction | ❌ | Missing | Proper LLM prompt formatting | 🔴 High |
| FoundationModelsWordGenerator | Attempt looping (max 4 attempts) | ❌ | Missing | Retry logic with exponential backoff | 🔴 High |
| FoundationModelsWordGenerator | JSON parsing and validation | ❌ | Missing | Robust parsing of LLM responses | 🔴 High |
| FoundationModelsWordGenerator | Candidate filtering (exclusions) | ❌ | Missing | Filtering generated pairs by exclusions | 🔴 High |
| FoundationModelsWordGenerator | Language script validation | ❌ | Missing | Ensuring generated text matches language | 🔴 High |
| FoundationModelsWordGenerator | Similarity score validation | ❌ | Missing | Ensuring scores are in valid range | 🔴 High |
| FoundationModelsWordGenerator | Difficulty range validation | ❌ | Missing | Matching similarity to difficulty | 🔴 High |
| NormalizationUtility | String normalization (lowercase, trim) | ❌ | Missing | Basic normalization | 🔴 High |
| NormalizationUtility | Diacritic removal | ❌ | Missing | Accent removal (é → e) | 🔴 High |
| NormalizationUtility | Punctuation/symbol removal | ❌ | Missing | Removal of punctuation and symbols | 🔴 High |
| NormalizationUtility | Whitespace collapsing | ❌ | Missing | Multiple spaces to single space | 🔴 High |
| NormalizationUtility | Pair key generation (order independence) | ❌ | Missing | Consistent keys regardless of order | 🔴 High |
| NormalizationUtility | Concept extraction from pairs | ❌ | Missing | Extracting both concepts from a pair | 🔴 High |
| NormalizationUtility | First non-empty extraction | ❌ | Missing | Getting first non-empty value | 🔴 High |
| NormalizationUtility | Preferred language extraction | ❌ | Missing | Language-specific extraction | 🟠 Medium |
| PlayedPairStore | Schema definition and modeling | ❌ | Missing | Correct SwiftData model setup | 🔴 High |
| PlayedPairStore | Used concepts retrieval | ❌ | Missing | Getting all used concepts for topic | 🔴 High |
| PlayedPairStore | Can use words checking | ❌ | Missing | Checking if words can be used | 🔴 High |
| PlayedPairStore | Marking pairs as played | ❌ | Missing | Persisting used pairs | 🔴 High |
| PlayedPairStore | History clearing | ❌ | Missing | Clearing play history | 🔴 High |
| PlayedPairStore | Count tracking | ❌ | Missing | Tracking number of used pairs | 🔴 High |
| PlayedPairStore | Topics listing | ❌ | Missing | Listing all topics with used pairs | 🔴 High |
| PlayedPairStore | In-memory fallback (when SwiftData fails) | ❌ | Missing | Graceful degradation to memory-only | 🔴 High |
| PlayedPairStore | Composite key uniqueness | ❌ | Missing | Ensuring no duplicate entries | 🔴 High |
| Various UI views | Loading states | ❌ | Missing | Displaying loading indicators | 🟠 Medium |
| Various UI views | Error states | ❌ | Missing | Displaying error messages | 🟠 Medium |
| Various UI views | Empty states | ❌ | Missing | Handling empty data scenarios | 🟠 Medium |
| Various UI views | User interaction handling | ❌ | Missing | Responding to taps, gestures, input | 🟠 Medium |
| Various UI views | Animation transitions | ❌ | Missing | Smooth state transitions | 🟠 Low |

## 3. Missing Tests

### AppState

Test:
1. Initial state verification
2. Successful topic loading
3. Bootstrap failure handling
4. Idempotent bootstrap (multiple calls)

Why each test matters:
- Initial state: Ensures app starts in correct state before data loading
- Successful loading: Verifies the happy path of app initialization
- Failure handling: Ensures app gracefully handles data loading failures
- Idempotent bootstrap: Prevents issues if bootstrap is called multiple times

### TopicService

Test:
1. Initial state (empty cache)
2. Local topics only (no AI)
3. AI topics only (no local)
4. Merged topics (local + AI)
5. Caching behavior (second call returns cached)
6. Normalization of topic IDs
7. Sorting of merged topics

Why each test matters:
- Cache behavior: Ensures performance optimization works correctly
- Source handling: Verifies both local and AI sources work independently and together
- Merging logic: Prevents duplicates and ensures consistent ordering
- Normalization: Ensures topic IDs are consistent for comparison
- Sorting: Guarantees predictable UI presentation

### WordRepository

Test:
1. Initialization from JSON
2. Handling missing/corrupted JSON
3. Topics list generation
4. Filtering by difficulty
5. Language localization filtering
6. Exclusion set filtering
7. Random pair selection
8. All pairs for topic (stats)

Why each test matters:
- Data loading: Core functionality of loading game data
- Error handling: App should not crash if data file is missing/corrupt
- Topic listing: Used for UI topic selection
- Difficulty filtering: Core game mechanic for word pair selection
- Language filtering: Ensures words are available in selected language
- Exclusion handling: Prevents repeated word pairs in same game session
- Random selection: Ensures fair and varied gameplay
- Stats display: Used for showing pair counts in UI

### GameEngine

Test:
1. Role assignment correctness
2. Role assignment with Mr. White
3. Role assignment without Mr. White
4. Board evaluation (counting roles)
5. Mr. White guess evaluation

Why each test matters:
- Role assignment: Core game mechanic that determines player information
- Mr. White handling: Special role that requires different treatment
- Board evaluation: Used throughout game to determine win conditions
- Guess evaluation: Determines if Mr. White wins the game

### GameViewModel

Test:
1. Player management (add/remove)
2. Game start flow
3. Word pair generation integration
4. Role assignment and distribution
5. Reveal phase handling
6. Discussion timer
7. Voting logic
8. Elimination process
9. Mr. White guessing
10. Game state synchronization
11. Replay functionality
12. New game reset
13. Error handling (word generation failures)
14. Topic preparation and caching

Why each test matters:
- Player management: Basic UI interaction for setting up game
- Game start: Main entry point for beginning gameplay
- Word generation: Integration with asynchronous word providers
- Role distribution: Ensures players get correct secret information
- Reveal phase: Core mechanic for showing players their words
- Discussion timer: Time-limited discussion phase
- Voting: Core elimination mechanic
- Elimination: Removing players from active gameplay
- Mr. White guessing: Special win condition for Mr. White
- State sync: Ensuring UI reflects actual game state
- Replay/New game: Restarting gameplay functionality
- Error handling: Graceful degradation when services fail
- Preparation/ caching: Performance optimization for responsiveness

### WordPairProvider

Test:
1. Initial Local pair generation
2. LLM background refill
3. Cache consumption (FIFO)
4. Cache threshold refill triggering
5. Exclusion handling (used concepts)
6. Cache conflict detection
7. Configuration change handling
8. Concurrent access safety
9. Error handling (generation failures)

Why each test matters:
- Initial pair: Ensures game can start quickly
- Background refill: Maintains adequate word pair supply during gameplay
- Cache consumption: Proper word pair usage without repetition
- Threshold refill: Proactive cache maintenance
- Exclusion handling: Prevents recently used concepts from appearing
- Conflict detection: Ensures variety in cached word pairs
- Configuration changes: Handling user changing game settings
- Concurrent safety: Preventing race conditions in async environment
- Error handling: Graceful degradation when word generation fails

### WordGeneratorService

Test:
1. Generator selection (Local first)
2. Generator availability checking
3. Error propagation

Why each test matters:
- Selection priority: Ensures fast local generator is tried first
- Availability checking: Prevents attempting to use unavailable services
- Error propagation: Ensures errors are properly communicated upstream

### LocalWordGenerator

Test:
1. Repository integration
2. Exclusion respect
3. Fallback behavior (no pairs)

Why each test matters:
- Repository integration: Correct use of core data source
- Exclusion respect: Prevents repetition of concepts
- Fallback behavior: Proper error handling when no local pairs available

### FoundationModelsWordGenerator

Test:
1. Availability checking (iOS 26+)
2. Language model availability
3. Prompt construction
4. Attempt looping (max 4 attempts)
5. JSON parsing and validation
6. Candidate filtering (exclusions)
7. Language script validation
8. Similarity score validation
9. Difficulty range validation

Why each test matters:
- Availability checking: Correctly identifies when AI generation is possible
- Model availability: Graceful handling when AI not available
- Prompt construction: Ensures AI receives properly formatted requests
- Attempt looping: Provides retry mechanism for unreliable AI
- JSON parsing: Robust handling of AI responses
- Candidate filtering: Ensures AI-generated pairs meet requirements
- Language validation: Prevents language mixing in generated content
- Score validation: Ensures similarity scores are usable
- Difficulty matching: Guarantees generated pairs match requested difficulty

### NormalizationUtility

Test:
1. String normalization (lowercase, trim)
2. Diacritic removal
3. Punctuation/symbol removal
4. Whitespace collapsing
5. Pair key generation (order independence)
6. Concept extraction from pairs
7. First non-empty extraction
8. Preferred language extraction

Why each test matters:
- Basic normalization: Foundation for consistent concept comparison
- Diacritic removal: Ensures "cafe" and "café" are treated as same concept
- Punctuation removal: Ensures "nike's" and "nikes" are treated same
- Whitespace handling: Ensures "new  york" and "new york" are same
- Pair key: Ensures (A,B) and (B,A) map to same key for uniqueness
- Concept extraction: Used for exclusion checking in word selection
- First non-empty: Deterministic concept representation
- Preferred language: UI-specific extraction with language preference

### PlayedPairStore

Test:
1. Schema definition and modeling
2. Used concepts retrieval
3. Can use words checking
4. Marking pairs as played
5. History clearing
6. Count tracking
7. Topics listing
8. In-memory fallback (when SwiftData fails)
9. Composite key uniqueness

Why each test matters:
- Schema modeling: Correct SwiftData setup for persistence
- Used concepts: Core exclusion mechanism for word selection
- Can use checking: Prevents reuse of concepts in same session
- Marking played: Persisting which concepts have been used
- History clearing: Ability to reset game state
- Count tracking: Analytics and debugging
- Topics listing: Understanding what topics have been played
- In-memory fallback: Ensures app works even if persistence fails
- Composite key: Prevents duplicate entries in database

### UI Views (representative samples)

Test:
1. Loading states
2. Error states
3. Empty states
4. User interaction handling
5. Animation transitions

Why each test matters:
- Loading states: Proper feedback during async operations
- Error states: User-friendly failure communication
- Empty states: Graceful handling of missing data
- User interaction: Correct response to user inputs
- Animation transitions: Smooth and polished user experience

## 4. Critical Edge Cases

### Data
- Empty word repository (corrupted/missing JSON)
- Single word pair in repository (edge case for random selection)
- Duplicate concepts in word pairs (same word for civilian/undercover)
- Missing localizations for certain languages
- Very long topic names or word combinations
- Special characters and emojis in word data
- Extremely large exclusion sets (near exhaustion of available pairs)

### Networking/AI
- Complete AI unavailability (device doesn't support FoundationModels)
- Intermittent AI connectivity/timeouts
- Malformed JSON responses from AI
- AI generating inappropriate or offensive content
- AI generating words that don't match requested difficulty
- AI generating words with wrong language/script
- Rate limiting from AI services
- Empty responses from AI generators

### Async/Await
- Task cancellation during word generation
- Concurrent game start attempts
- Rapid sequential game starts/stops
- Background tasks continuing after view dismissed
- Race conditions between local and AI generation
- Timer firing during state transitions
- Async sequences not properly cleaned up

### State Transitions
- Invalid event sequences (trying to vote before discussion)
- Rapid firing of same event (multiple taps)
- State transitions with boundary player counts (3, 4 players)
- Transitioning from results directly to discussion (skipping setup)
- Handling events after game is supposedly over
- Concurrent state mutation from multiple sources

### Memory/Resource
- Low memory conditions during caching
- Rapid creation/destruction of GameViewModels
- Large numbers of stored played pairs (persistence bloat)
- Concurrent access to shared resources (UserDefaults, etc.)
- Background termination during async operations

## 5. Async / Concurrency Analysis

The codebase makes extensive use of Swift Concurrency (async/await) and actors for thread safety. Key concurrency aspects that should be tested:

### Actors and Isolation
- TopicService (actor) - tests should verify isolation and proper await behavior
- WordPairProvider (@MainActor) - tests should verify MainActor execution
- WordGeneratorService (actor) - tests should verify isolation
- PlayedPairStore (actor) - tests should verify isolation and concurrent access safety
- LocalWordGenerator/ForecastModelsWordGenerator (actors) - tests should verify isolation

### async/await Patterns
- GameViewModel.startGame() - complex async flow with error handling
- WordPairProvider.nextPair() - sophisticated async coordination
- WordPairProvider.prepareForGameStart() - async initialization with background tasks
- WordProviderService methods - async generator orchestration
- AsyncMutex usage in WordPairProvider - testing lock behavior

### Critical Concurrency Scenarios to Test:
1. **Cancellation**: What happens when tasks are cancelled mid-execution?
2. **Race conditions**: What if local and AI generation complete in unexpected order?
3. **MainActor updates**: Are all UI-published properties updated on MainActor?
4. **Task isolation**: Are actor-isolated properties properly protected?
5. **Concurrent access**: What happens when multiple threads access shared state?
6. **Background task cleanup**: Are tasks properly cancelled when no longer needed?
7. **Error propagation**: How are errors handled in async chains?
8. **Retry behavior**: How do retry mechanisms behave under failure conditions?

Specific examples that should be tested:
- What happens if startGame() is called twice rapidly?
- What happens if the user changes topic while word generation is in progress?
- What happens if network request times out during word pair generation?
- What happens if multiple players try to vote simultaneously?
- What happens if a timer fires during a state transition?
- What happens if the app goes to background during async word generation?

## 6. Architecture & Testability

### Strengths (makes testing easier):
1. **Dependency Injection**: Most components accept dependencies via init (TopicService, WordPairProvider, etc.)
2. **Protocol-oriented design**: Generators use protocols, enabling easy mocking
3. **Pure functions/value types**: GameStateMachine and GameEngine are highly testable without mocks
4. **Clear separation of concerns**: Data, domain, presentation layers are well separated
5. **Actor-based concurrency**: Built-in thread safety for shared state
6. **Protocol extensibility**: Easy to substitute implementations for testing

### Weaknesses (makes testing harder):
1. **Static/global dependencies**: Some utilities like NormalizationUtility are static (though this is appropriate for pure functions)
2. **Complex async chains**: WordProviderService has intricate async logic that's challenging to test
3. **SwiftData dependency**: PlayedPairStore ties testing to persistence layer
4. **MainActor constraints**: Some @MainActor properties require MainActor context for testing
5. **External service integration**: FoundationModelsWordGenerator ties to OS availability
6. **Bundle dependencies**: WordRepository loads from Bundle.main, complicating test isolation

### Specific Testability Concerns:
1. **TopicService**: Direct instantiation makes dependency injection awkward (has default params)
2. **WordRepository**: Relies on Bundle.main for JSON loading - hard to substitute test data
3. **PlayedPairStore**: Requires SwiftData ModelContainer - complex to set up in tests
4. **FoundationModelsWordGenerator**: Heavily dependent on OS availability checks
5. **GameViewModel**: Complex async lifecycle with many moving parts
6. **WordPairProvider**: Intricate caching logic with multiple concurrent tasks

Despite these concerns, the architecture is generally testable with appropriate techniques:
- Use dependency injection where available
- Create test doubles for protocols
- Use pre-loaded test data instead of Bundle.main
- Use in-memory SwiftData configurations
- Test async behavior with XCTestExpectation or modern async testing
- Focus on behavioral testing rather than implementation details

## 7. Sample Tests

**SAMPLE TEST — DO NOT APPLY DIRECTLY**

### AppState Tests
```swift
import Testing
@testable import undercover

@MainActor
struct AppStateTests {

    @Test
    func testInitialState() async {
        let appState = AppState()
        
        #expect(appState.topics.isEmpty)
        #expect(appState.isReady == false)
    }

    @Test
    func testBootstrapSuccess() async {
        // Given
        let appState = AppState()
        
        // When
        await appState.bootstrap()
        
        // Then
        #expect(appState.isReady == true)
        // Note: Actual topic count depends on bundled data
    }

    @Test
    func testBootstrapIdempotent() async {
        // Given
        let appState = AppState()
        
        // When
        await appState.bootstrap()
        let firstCallTopics = appState.topics
        await appState.bootstrap() // Second call
        
        // Then
        #expect(appState.topics == firstCallTopics)
        #expect(appState.isReady == true)
    }
}
```

**Explanation:**
- **Given**: AppState instance in initial state
- **When**: Calling bootstrap() method
- **Then**: Verify topics are loaded and isReady is set to true
- **Value**: Tests app initialization behavior
- **Bugs prevented**: App starting in wrong state, bootstrap not working
- **Type**: Unit test
- **Priority**: High

**SAMPLE TEST — DO NOT APPLY DIRECTLY**

### TopicService Tests
```swift
import Testing
@testable import undercover

struct TopicServiceTests {

    @Test
    func testLocalTopicsOnly() async {
        // Given
        let repository = TestWordRepository(topics: ["animals", "food"])
        let service = TopicService(repository: repository, aiProvider: nil)
        
        // When
        let topics = await service.topics()
        
        // Then
        #expect(topics.count == 2)
        #expect(topics.contains { $0.name == "Animals" })
        #expect(topics.contains { $0.name == "Food" })
        #expect(allTopicsHaveSource(.local, topics))
    }

    @Test
    func testAITopicsOnly() async {
        // Given
        let repository = TestWordRepository(topics: [])
        let aiProvider = TestAIProvider(topics: ["movies", "games"])
        let service = TopicService(repository: repository, aiProvider: aiProvider)
        
        // When
        let topics = await service.topics()
        
        // Then
        #expect(topics.count == 2)
        #expect(topics.contains { $0.name == "Movies" })
        #expect(topics.contains { $0.name == "Games" })
        #expect(allTopicsHaveSource(.ai, topics))
    }

    @Test
    func testMergedTopicsDeduplication() async {
        // Given
        let repository = TestWordRepository(topics: ["animals", "food"])
        let aiProvider = TestAIProvider(topics: ["food", "travel"]) // "food" duplicated
        let service = TopicService(repository: repository, aiProvider: aiProvider)
        
        // When
        let topics = await service.topics()
        
        // Then
        #expect(topics.count == 3) // Should be 3, not 4 due to deduplication
        #expect(topics.contains { $0.name == "Animals" })
        #expect(topics.contains { $0.name == "Food" })
        #expect(topics.contains { $0.name == "Travel" })
        #expect(topicsAreSorted(topics)) // Should be alphabetically sorted
    }

    @Test
    func testCachingBehavior() async {
        // Given
        let repository = TestWordRepository(topics: ["animals"])
        let service = TopicService(repository: repository, aiProvider: nil)
        
        // When
        let firstCall = await service.topics()
        let secondCall = await service.topics()
        
        // Then
        #expect(firstCall == secondCall)
        // Verify it's actually cached by checking internal state (would need test access)
    }

    // Helper functions and test doubles would be needed
    private func allTopicsHaveSource(_ source: GameTopic.Source, _ topics: [GameTopic]) -> Bool {
        topics.allSatisfy { $0.source == source }
    }
    
    private func topicsAreSorted(_ topics: [GameTopic]) -> Bool {
        topics == topics.sorted { $0.name < $1.name }
    }
}
```

**Explanation:**
- **Given**: TopicService with controlled dependencies (test doubles)
- **When**: Calling topics() method
- **Then**: Verify correct topics are returned with proper sources and deduplication
- **Value**: Tests topic loading, merging, deduplication, and sorting logic
- **Bugs prevented**: Duplicate topics, missing topics, wrong topic sources
- **Type**: Unit test
- **Priority**: High

**SAMPLE TEST — DO NOT APPLY DIRECTLY**

### GameEngine Tests
```swift
import Testing
@testable import undercover

struct GameEngineTests {

    @Test
    func testRoleAssignment_ThreePlayers() {
        // Given
        let engine = GameEngine()
        let players = [
            Player(id: UUID(), name: "Alice", isEliminated: false),
            Player(id: UUID(), name: "Bob", isEliminated: false),
            Player(id: UUID(), name: "Charlie", isEliminated: false)
        ]
        let pair = WordPair(
            civilian: LocalizedWord(values: [AppLanguage.english.rawValue: "cat"]),
            undercover: LocalizedWord(values: [AppLanguage.english.rawValue: "dog"]),
            topic: "pets",
            similarity: 0.5
        )
        
        // When
        let assignment = engine.assign(
            players: players,
            pair: pair,
            language: .english,
            includeMrWhite: false
        )
        
        // Then
        #expect(assignment.wordsByPlayer.count == 3)
        #expect(assignment.rolesByPlayer.count == 3)
        
        // Exactly one undercover, rest civilians
        let undercoverCount = assignment.rolesByPlayer.values.filter { $0 == .undercover }.count
        let civilianCount = assignment.rolesByPlayer.values.filter { $0 == .civilian }.count
        
        #expect(undercoverCount == 1)
        #expect(civilianCount == 2)
        
        // Verify Mr. White not assigned when not requested
        #expect(assignment.rolesByPlayer.values.contains(.mrWhite) == false)
        
        // Verify words are assigned correctly
        #expect(assignment.undercoverPlayerID != nil)
        #expect(assignment.mrWhitePlayerID == nil)
    }

    @Test
    func testRoleAssignment_FourPlayersWithMrWhite() {
        // Given
        let engine = GameEngine()
        let players = [
            Player(id: UUID(), name: "Alice", isEliminated: false),
            Player(id: UUID(), name: "Bob", isEliminated: false),
            Player(id: UUID(), name: "Charlie", isEliminated: false),
            Player(id: UUID(), name: "David", isEliminated: false) // Mr. White
        ]
        let pair = WordPair(
            civilian: LocalizedWord(values: [AppLanguage.english.rawValue: "cat"]),
            undercover: LocalizedWord(values: [AppLanguage.english.rawValue: "dog"]),
            topic: "pets",
            similarity: 0.5
        )
        
        // When
        let assignment = engine.assign(
            players: players,
            pair: pair,
            language: .english,
            includeMrWhite: true
        )
        
        // Then
        #expect(assignment.wordsByPlayer.count == 4)
        #expect(assignment.rolesByPlayer.count == 4)
        
        // Exactly one of each role type
        let undercoverCount = assignment.rolesByPlayer.values.filter { $0 == .undercover }.count
        let mrWhiteCount = assignment.rolesByPlayer.values.filter { $0 == .mrWhite }.count
        let civilianCount = assignment.rolesByPlayer.values.filter { $0 == .civilian }.count
        
        #expect(undercoverCount == 1)
        #expect(mrWhiteCount == 1)
        #expect(civilianCount == 2)
        
        #expect(assignment.undercoverPlayerID != nil)
        #expect(assignment.mrWhitePlayerID != nil)
    }

    @Test
    func testBoardEvaluation() {
        // Given
        let engine = GameEngine()
        let players = [
            Player(id: UUID(), name: "Alice", isEliminated: false),
            Player(id: UUID(), name: "Bob", isEliminated: false),
            Player(id: UUID(), name: "Charlie", isEliminated: false),
            Player(id: UUID(), name: "David", isEliminated: false)
        ]
        var rolesByPlayer: [UUID: PlayerRole] = [:]
        
        // Set up: 2 civilians, 1 undercover, 1 mr white
        rolesByPlayer[players[0].id] = .civilian
        rolesByPlayer[players[1].id] = .civilian
        rolesByPlayer[players[2].id] = .undercover
        rolesByPlayer[players[3].id] = .mrWhite
        
        // When
        let result = engine.evaluateBoard(
            alivePlayers: players,
            rolesByPlayer: rolesByPlayer
        )
        
        // Then
        #expect(result.aliveCivilians == 2)
        #expect(result.aliveUndercover == 1)
        #expect(result.aliveMrWhite == 1)
    }

    @Test
    func testMrWhiteGuessEvaluation() {
        // Given
        let engine = GameEngine()
        
        // When/Then
        #expect(engine.evaluateMrWhiteGuess("CAT", "cat") == true) // Case insensitive
        #expect(engine.evaluateMrWhiteGuess(" cat ", "cat") == true) // Trimmed
        #expect(engine.evaluateMrWhiteGuess("dog", "cat") == false) // Wrong guess
        #expect(engine.evaluateMrWhiteGuess("", "cat") == false) // Empty guess
    }
}
```

**Explanation:**
- **Given**: GameEngine instance and test data (players, word pair)
- **When**: Calling assign() or evaluate methods
- **Then**: Verify correct role distribution, board evaluation, and guess evaluation
- **Value**: Tests core game mechanics that determine player information and win conditions
- **Bugs prevented**: Incorrect role assignments, wrong win conditions, faulty Mr. White guessing
- **Type**: Unit test
- **Priority**: High

**SAMPLE TEST — DO NOT APPLY DIRECTLY**

### GameViewModel Tests (async)
```swift
import Testing
@testable import undercover

@MainActor
struct GameViewModelTests {

    @Test
    func testPlayerManagement() async {
        // Given
        let viewModel = GameViewModel()
        
        // When
        viewModel.addPlayer(name: "Alice")
        viewModel.addPlayer(name: "Bob")
        
        // Then
        #expect(viewModel.players.count == 2)
        #expect(viewModel.players.first?.name == "Alice")
        #expect(viewModel.players.last?.name == "Bob")
        
        // When removing
        viewModel.removePlayer(at: IndexSet(integer: 0))
        
        // Then
        #expect(viewModel.players.count == 1)
        #expect(viewModel.players.first?.name == "Bob")
    }

    @Test
    func testStartGameTooFewPlayers() async {
        // Given
        let viewModel = GameViewModel()
        viewModel.addPlayer(name: "Alice") // Only 1 player
        
        // When
        await viewModel.startGame()
        
        // Then
        #expect(viewModel.gameState == .setup) // Should not start game
        #expect(viewModel.isGeneratingWords == false)
    }

    @Test
    func testStartGameSuccess() async {
        // Given
        let viewModel = GameViewModel()
        // Add minimum 3 players
        viewModel.addPlayer(name: "Alice")
        viewModel.addPlayer(name: "Bob")
        viewModel.addPlayer(name: "Charlie")
        viewModel.selectedTopic = "animals"
        
        // Mock the wordPairProvider to return a known pair
        // This would require dependency injection or swizzling in real implementation
        
        // When
        await viewModel.startGame()
        
        // Then
        #expect(viewModel.isGeneratingWords == false) // Should complete
        #expect(viewModel.gameState == .reveal(index: 0, step: .passDevice)) // Progress to reveal
        // Additional assertions about assignments, roles, etc. would go here
    }

    @Test
    func testRevealFlow() async {
        // Given
        let viewModel = GameViewModel()
        // Set up a game in reveal state
        viewModel.gameState = .reveal(index: 0, step: .passDevice)
        viewModel.revealOrder = [UUID(), UUID(), UUID()] // 3 players
        
        // When
        viewModel.revealTapped()
        
        // Then
        #expect(viewModel.currentRevealStep == .showWord)
        
        // When
        viewModel.revealNext()
        
        // Then
        #expect(viewModel.currentRevealIndex == 1)
        #expect(viewModel.currentRevealStep == .passDevice)
        
        // When advancing to last player
        viewModel.revealNext()
        viewModel.revealNext()
        
        // Then
        #expect(viewModel.gameState == .discussion(round: 1)) // Should advance to discussion
    }

    @Test
    func testDiscussionTimer() async {
        // Given
        let viewModel = GameViewModel()
        
        // When
        viewModel.startDiscussionTimer(seconds: 2)
        
        // Then
        #expect(viewModel.isTimerRunning == true)
        #expect(viewModel.timeRemaining == 2)
        
        // Note: Actual timer testing would require waiting or mocking
        // In practice, you'd test the logic that handles timer completion
    }
}
```

**Explanation:**
- **Given**: GameViewModel instance in specific state
- **When**: Calling methods like addPlayer, startGame, revealTapped, etc.
- **Then**: Verify state changes and property updates
- **Value**: Tests UI logic integration with game mechanics
- **Bugs prevented**: UI not reflecting game state, incorrect player management, broken game flow
- **Type**: Unit test (with @MainActor for MainActor-bound properties)
- **Priority**: High

**SAMPLE TEST — DO NOT APPLY DIRECTLY**

### WordPairProvider Tests (async)
```swift
import Testing
@testable import undercover

@MainActor
struct WordPairProviderTests {

    @Test
    func testCacheConsumption() async {
        // Given
        let provider = WordPairProvider()
        // Manually populate cache for testing (would need test access or dependency injection)
        // For demonstration, showing what the test would verify
        
        // When/Then
        #expect(try await provider.nextPair(
            playerCount: 3,
            topic: "test",
            language: .english,
            difficulty: .medium
        ) != nil) // Would succeed if cache had valid pairs
    }

    @Test
    func testConfigurationChangeResetsCache() async {
        // Given
        let provider = WordPairProvider()
        
        // When
        provider.prepareIfNeeded(
            playerCount: 3,
            topic: "animals",
            language: .english,
            difficulty: .medium
        )
        // Change configuration
        provider.prepareIfNeeded(
            playerCount: 3,
            topic: "food",
            language: .spanish,
            difficulty: .hard
        )
        
        // Then
        #expect(provider.preparedWordPairs.isEmpty) // Cache should be reset
        #expect(provider.preparedConfiguration?.topic == "food")
        #expect(provider.preparedConfiguration?.language == .spanish)
        #expect(provider.preparedConfiguration?.difficulty = .hard)
    }
}
```

**Explanation:**
- **Given**: WordPairProvider instance
- **When**: Calling methods like prepareIfNeeded or nextPair
- **Then**: Verify cache behavior and configuration handling
- **Value**: Tests word pair caching logic that affects game performance and variety
- **Bugs prevented**: Stale or incorrect word pairs, cache not refilling, configuration leaks
- **Type**: Unit test
- **Priority**: High

**SAMPLE TEST — DO NOT APPLY DIRECTLY**

### NormalizationUtility Tests
```swift
import Testing
@testable import undercover

struct NormalizationUtilityTests {

    @Test
    func testBasicNormalization() {
        #expect(NormalizationUtility.normalize("  Hello World  ") == "hello world")
        #expect(NormalizationUtility.normalize("HELLO") == "hello")
    }

    @Test
    func testDiacriticRemoval() {
        #expect(NormalizationUtility.normalize("Café") == "cafe")
        #expect(NormalizationUtility.normalize("Niño") == "nino")
        #expect(NormalizationUtility.normalize("résumé") == "resume")
    }

    @Test
    func testPunctuationAndSymbolRemoval() {
        #expect(NormalizationUtility.normalize("Nike's") == "nike s")
        #expect(NormalizationUtility.normalize("Rock & Roll") == "rock  roll")
        #expect(NormalizationUtility.normalize("Price: $100") == "price  100")
    }

    @Test
    func testWhitespaceCollapsing() {
        #expect(NormalizationUtility.normalize("New    York") == "new york")
        #expect(NormalizationUtility.normalize("\tHello\n\nWorld\t") == "hello world")
    }

    @Test
    func testPairKeyOrderIndependence() {
        #expect(NormalizationUtility.pairKey("nike", "adidas") == "adidas|nike")
        #expect(NormalizationUtility.pairKey("adidas", "nike") == "adidas|nike")
        #expect(NormalizationUtility.pairKey("CAT", "Dog") == "cat|dog")
    }

    @Test
    func testConceptExtraction() {
        let concepts = NormalizationUtility.conceptsFromPair(
            civilian: "Nike Shoes",
            undercover: "Adidas Sneakers"
        )
        #expect(concepts == ["nike", "shoes", "adidas", "sneakers"])
    }

    @Test
    func testFirstNonEmpty() {
        #expect(NormalizationUtility.firstNonEmpty(from: ["en": "Hello", "fr": ""]) == "Hello")
        #expect(NormalizationUtility.firstNonEmpty(from: ["en": "", "fr": "Bonjour"]) == "Bonjour")
        #expect(NormalizationUtility.firstNonEmpty(from: ["en": "", "fr": ""]) == "")
    }

    @Test
    func testPreferredLanguage() {
        let values = ["en": "Hello", "fr": "Bonjour", "es": "Hola"]
        #expect(NormalizationUtility.firstNonEmpty(in: values, preferredLanguages: ["fr", "en"]) == "Bonjour")
        #expect(NormalizationUtility.firstNonEmpty(in: values, preferredLanguages: ["xx", "en"]) == "Hello")
        #expect(NormalizationUtility.firstNonEmpty(in: values, preferredLanguages: ["xx", "yy"]) == "")
    }
}
```

**Explanation:**
- **Given**: Input strings to normalize
- **When**: Calling normalization methods
- **Then**: Verify correctly normalized output
- **Value**: Tests foundation utilities that ensure consistent concept comparison throughout the app
- **Bugs prevented**: Concept matching failures due to formatting differences, duplicate concept detection failures
- **Type**: Unit test
- **Priority**: High

## 8. Test Quality Issues

The existing GameStateMachineTests are generally well-written, but there are some areas for improvement:

### What's Done Well:
1. **Behavioral testing**: Tests focus on state transitions and outcomes, not implementation details
2. **Comprehensive scenario coverage**: Tests cover various player counts and elimination sequences
3. **Clear test organization**: Tests are grouped by scenario with descriptive names
4. **Deterministic testing**: No reliance on timing or randomness
5. **Appropriate use of #expect**: Clear assertions about expected states

### Areas for Improvement:
1. **Some tests could be more concise**: Several test scenarios share similar setup that could be extracted
2. **Edge case documentation**: While edge cases are tested, the specific edge case being tested isn't always clear from the test name
3. **Missing negative tests**: Few tests for invalid event sequences (though the FSM gracefully ignores them)
4. **Test data readability**: Some test data (player counts) could be better explained in comments

### No Significant Test Quality Issues Found:
Since the test suite is limited to GameStateMachineTests, there are no widespread issues like:
- Testing implementation details instead of behavior
- Weak or missing assertions
- Overly broad assertions
- Flaky timing-based tests
- Excessive sleeps
- Brittle mocks
- Tests coupled to internal implementation
- Missing verification of dependency calls
- Tests that don't test failure paths

The main "issue" is simply the lack of tests for other components, not quality issues with existing tests.

## 9. Prioritized Test Plan

### 🔴 Must Test (Critical - High Risk if Untested)
These components, if broken, would prevent core gameplay or cause crashes:

1. **GameViewModel.startGame()** - Main entry point for gameplay
2. **GameViewModel player management** - Adding/removing players
3. **WordPairProvider.nextPair()** - Core word pair supply during gameplay
4. **WordRepository.randomPair()** - Core data access for word pairs
5. **TopicService.topics()** - Topic loading for game setup
6. **GameEngine.assign()** - Role assignment (core game mechanic)
7. **AppState.bootstrap()** - App initialization
8. **NormalizationUtility** - Foundation for concept comparison
9. **PlayedPairStore.usedConcepts()** - Core exclusion mechanism
10. **PlayedPairStore.markAsPlayed()** - Persistence of game state

### 🟠 Should Test (Important - Medium Risk if Untested)
These components affect gameplay quality, performance, or edge cases:

11. **GameViewModel reveal/voting/elimination flows** - Core gameplay phases
12. **GameViewModel timer functionality** - Time-limited discussions
13. **WordPairProvider caching logic** - Performance optimization
14. **WordPairProvider background refill** - Maintaining word pair supply
15. **GameEngine.boardEvaluation()** - Win condition detection
16. **GameEngine.Mr. White guess evaluation** - Special win condition
17. **LocalWordGenerator.randomPair()** - Local word generation
18. **FoundationModelsWordGenerator** - AI word generation (when available)
19. **WordGeneratorService** - Generator orchestration
20. **Various UI states** (loading, error, empty) - User experience
21. **AppState.bootstrap idempotent** - Safe multiple calls
22. **TopicService caching** - Performance optimization

### 🟢 Nice to Have (Lower Risk if Untested)
These components enhance robustness but are less critical:

23. **WordRepository error handling** (missing/corrupted JSON)
24. **WordRepository.allPairs(for:)** (stats display)
25. **GameViewModel replay/new game** - Restart functionality
26. **GameViewModel error handling** - Graceful degradation
27. **PlayedPairStore history clearing** - Reset functionality
28. **PlayedPairStore count/topics** - Analytics
29. **PlayedPairStore in-memory fallback** - Resilience
30. **TopicService AI-only/local-only modes** - Feature completeness
31. **NormalizationUtility preferred language** - UI-specific extraction
32. **Various UI interaction handling** - Polish
33. **Various UI animation transitions** - Polish
34. **TopicService sorting** - Predictable UI presentation
35. **WordRepository topics list generation** - Topic selection UI
36. **WordRepository language filtering** - Multi-language support
37. **WordRepository difficulty filtering** - Core mechanic
38. **WordRepository exclusion set filtering** - Core mechanic
39. **WordRepository random distribution** - Fairness
40. **WordPairProvider conflict detection** - Cache variety
41. **WordPairProvider concurrent access safety** - Thread safety
42. **WordPairProvider error handling** - Fallback behavior
43. **WordGeneratorService error propagation** - Error handling
44. **WordGeneratorService availability checking** - Service availability
45. **LocalWordGenerator exclusion respect** - Core mechanic
46. **LocalWordGenerator fallback behavior** - Error handling
47. **FoundationModelsWordGenerator availability checking** - Feature detection
48. **FoundationModelsWordGenerator prompt construction** - AI interaction
49. **FoundationModelsWordGenerator attempt looping** - Retry logic
50. **FoundationModelsWordGenerator JSON parsing** - Response handling
51. **FoundationModelsWordGenerator candidate filtering** - Quality control
52. **FoundationModelsWordGenerator language script validation** - Language correctness
53. **FoundationModelsWordGenerator similarity score validation** - Data validity
54. **FoundationModelsWordGenerator difficulty range validation** - Requirement matching

### Recommended Order

1. **NormalizationUtility** - Foundation for all concept comparison
2. **PlayedPairStore** - Core exclusion mechanism
3. **WordRepository** - Data loading layer
4. **TopicService** - Topic loading
5. **GameEngine** - Core game mechanics (role assignment, evaluation)
6. **GameViewModel** - UI integration and game flow
7. **WordPairProvider** - Performance optimization (caching)
8. **WordGeneratorService & LocalWordGenerator** - Word generation
9. **FoundationModelsWordGenerator** - AI word generation (conditional)
10. **UI states and interactions** - User experience
11. **AppState** - App initialization
12. **Analytics and resilience features** - Nice-to-have enhancements

## 10. Final Assessment

The current test suite provides good coverage for the GameStateMachine, which is a complex piece of business logic with many state transitions. However, this represents only a small fraction of the overall codebase's behavioral surface area.

**Confidence Assessment:**
- **High confidence**: Game state transitions (covered by existing tests)
- **Low confidence**: Nearly everything else including data loading, networking, UI logic, and performance optimizations

**Biggest Testing Gaps:**
1. **Initialization and data loading** (AppState, TopicService, WordRepository) - If these fail, the app may not start or show correct data
2. **Core gameplay mechanics** (GameEngine, GameViewModel) - If these fail, core gameplay is broken
3. **Performance optimizations** (WordPairProvider caching) - If these fail, gameplay may be slow or repetitive
4. **Error handling** throughout - If these fail, app may crash or behave poorly under adverse conditions
5. **Async/await coordination** - If these fail, app may have race conditions, crashes, or unresponsive UI

**Recommendation:**
Focus initial testing efforts on the "Must Test" list, particularly:
1. Start with foundational utilities (NormalizationUtility, PlayedPairStore)
2. Work through the data loading layer (WordRepository, TopicService)
3. Test core game mechanics (GameEngine)
4. Test UI integration (GameViewModel)
5. Test performance optimizations (WordPairProvider)

This approach will provide the greatest risk reduction per testing effort, ensuring that the most critical paths through the application are covered by automated tests.
