# undercover

A sophisticated social deduction game built with SwiftUI where players must blend in while trying to identify the hidden infiltrator.

## Overview

Undercover is a modern iOS implementation of the classic social deduction game. Players are secretly assigned roles and words, creating tense rounds of discussion, deduction, and bluffing:

- **Civilions**: Most players who know the common word
- **Undercover**: Players who know a similar but different word  
- **Mr. White**: The blind player who knows nothing and must bluff

Through timed discussion rounds, players share clues about their words without revealing them directly. After discussion, the group votes to eliminate a suspect. If Mr. White survives to the end, he gets one chance to guess the civilian word and win instantly.

The game continues through multiple rounds until one faction achieves victory through elimination or successful bluffing.

## Features

### Core Gameplay
- **Social deduction mechanics** with Civilians, Undercover, and Mr. White roles
- **Timed discussion phases** encouraging quick thinking and bluffing
- **Voting system** for player elimination
- **Mr. White guess mechanic** for instant win/loss conditions
- **Multiple victory conditions** based on faction elimination and parity

### Technical Implementation
- **Pure SwiftUI** interface with custom Design System
- **Deterministic Game State Machine** as a zero-dependency value type
- **Stateless Game Engine** for role assignment and win condition evaluation
- **Hierarchical word generation** with local fallback to Apple Foundation Models
- **Complete localization** supporting 5 languages including RTL (Arabic, Tunisian Arabic)
- **Accessibility support** with VoiceOver labels, Dynamic Type, and Reduce Motion
- **Haptic feedback** and particle effects for enhanced immersion

### AI Integration
- **Apple Foundation Models** for on-device AI-generated word pairs (iOS 26.0+)
- **Intelligent fallback system** that uses local word database when AI unavailable
- **Background preparation** of AI-generated content for seamless gameplay
- **Topic-based generation** with difficulty scaling (Easy/Medium/Hard)

## Architecture

The project follows a clean separation of concerns:

```
Game Rules & Logic
        ↓
Deterministic State Transitions (FSM)
        ↓
ViewModel Orchestration & State Binding
        ↓
SwiftUI Presentation Layer
```

### Key Components

- **GameStateMachine**: Pure value-type finite state machine handling all game logic transitions. Fully unit-testable with zero dependencies.
- **GameEngine**: Stateless functions for role assignment, word distribution, and win condition evaluation.
- **GameViewModel**: ObservableObject that bridges the FSM/Engine to SwiftUI, managing player state, timers, and UI synchronization.
- **WordGeneratorService**: Orchestrates local and AI-powered word generators with fallback chains.
- **TopicService**: Manages local and AI-generated topics for word pair generation.
- **Design System**: Centralized tokens, reusable components, and consistent styling.
- **AppState**: Handles app startup, topic loading, and Foundation Models availability.

### Game State Machine Flow

```text
setup
  ↓
loadingWords (fetches/distributes word pairs)
  ↓
reveal (players see their words in sequence)
  ↓
discussion (timed clue-sharing phase)
  ↓
voting (elimination vote)
  ↓
mrWhiteGuess (if Mr. White survives elimination)
  ↓
results (victory determined)
  ↓
(replay or new game)
```

The FSM is a pure Sendable struct with deterministic transitions based on player counts and elimination results, making it entirely suitable for unit testing.

## AI / Foundation Models

Undercover leverages Apple's on-device Foundation Models for creative word pair generation:

- **Availability**: Requires iOS 26.0+ with Apple Intelligence
- **Usage**: Generates contextual civilian/undercover word pairs based on selected topics
- **Fallback**: Gracefully degrades to local word database when AI unavailable
- **Background Loading**: AI topics load asynchronously after local topics are available
- **Privacy**: All processing occurs on-device; no data leaves the user's device

When Foundation Models is available, the app attempts to generate word pairs using AI first, falling back to the local curated database only when necessary or when AI is unavailable.

## Localization

Undercover supports 5 languages with complete UI translation:

- English (`en`)
- French (`fr`) 
- Arabic (`ar`) - Right-to-Left layout support
- Spanish (`es`)
- Tunisian Arabic (`tn`) - Right-to-Left layout support

Localization is managed through:
- **AppLanguage**: Enum defining language metadata including RTL support
- **AppStrings**: Localized strings for all UI elements with proper plurals and context
- **LayoutDirection**: Automatic right-to-left layout for Arabic and Tunisian Arabic
- **Localization testing**: Verified through AppString previews and runtime language switching

## Accessibility

The app implements multiple accessibility features:

- **VoiceOver**: Comprehensive labels and hints for all interactive elements
- **Dynamic Type**: Text scales with user's preferred text size
- **Reduce Motion**: Animations respect system Reduce Motion setting
- **Accessible Navigation**: Logical tab order and screen titles
- **Color Contrast**: Sufficient contrast ratios for text and UI elements
- **Touch Targets**: Adequately sized interactive elements per Apple guidelines

## Tech Stack

| Technology | Usage |
|------------|-------|
| Swift 5.0 | Primary programming language |
| SwiftUI | Declarative UI framework |
| Foundation | Core functionality (data modeling, concurrency) |
| Foundation Models | On-device AI generation (iOS 26.0+) |
| Combine | Reactive state management in ViewModel |
| XCTest | Unit testing framework |
| XCTest/UI Testing | UI and integration testing |

## Requirements

- **Minimum iOS Version**: 26.5 (for Foundation Models compatibility)
- **Recommended iOS Version**: 26.0+ for full AI features
- **Development**: Xcode 15.0+, Swift 5.0
- **Devices**: iPhone and iPad (Universal iOS app)
- **Apple Silicon**: Runs on all modern Apple devices with iOS 26.5+

Note: While Foundation Models requires iOS 26.0+, the game remains fully functional using the local word database on older iOS versions.

## Project Structure

```text
undercover/
├── undercover/                    # Main app target
│   ├── App/                       # App entry point and lifecycle
│   ├── Domain/                    # Business logic (game rules, models)
│   │   └── Game/                  # GameStateMachine, GameEngine
│   ├── Presentation/              # UI and presentation layer
│   │   ├── DesignSystem/          # Reusable components, tokens, styles
│   │   ├── Game/                  # GameViewModel, WordPairProviding
│   │   └── Screens/               # Individual views (Home, Lobby, Game screens)
│   ├── Services/                  # Business services (word gen, topics)
│   │   ├── Topics/                # TopicService and providers
│   │   └── WordGeneration/        # Word generators and orchestration
│   ├── Shared/                    # Shared utilities and localization
│   │   ├── Concurrency/           # AsyncMutex and threading utilities
│   │   ├── Localization/          # AppLanguage, AppStrings, normalization
│   │   └── Utilities/             # Helper functions
│   └── Resources/                 # Assets, configuration, word database
└── undercoverTests/               # Unit tests
    ├── GameLogicTests/            # FSM, Engine, Model tests
    ├── ServiceTests/              # Word generation, topic service tests
    └── ViewModelTests/            # GameViewModel and UI logic tests
```

## Testing

The project includes comprehensive unit tests covering:

- **GameStateMachine**: All state transitions and victory conditions (15+ test scenarios)
- **GameEngine**: Role assignment and board evaluation logic
- **WordGeneratorService**: Local and AI-powered generation chains
- **LocalWordGenerator**: Offline word pair selection from database
- **FoundationModelsWordGenerator**: AI integration and prompt handling
- **TopicService**: Local and AI topic management
- **AppState**: Bootstrap and topic loading logic
- **GameViewModel**: UI state synchronization and game flow
- **NormalizationUtility**: Text processing for comparison and matching
- **PlayedPairStore**: Tracking of previously used word pairs

Tests verify deterministic behavior, edge cases, and proper state transitions under various player configurations and role distributions.

## Design Philosophy

Undercover was built with these guiding principles:

- **Simple SwiftUI Architecture**: Preferring view composition over complex abstractions
- **Deterministic Game Logic**: Pure functions and value types for predictable, testable behavior
- **Separation of Concerns**: Clear boundaries between game rules, state management, and UI
- **Reusable Design System**: Centralized tokens and components for visual consistency
- **Accessibility First**: Built-in VoiceOver support and adaptive interfaces
- **Global Readiness**: Complete localization with
