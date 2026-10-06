# Undercover App Architecture

## Overview

This document describes the architecture of the Undercover app, a social deduction game where players must identify the undercover agent based on similar-but-different word associations.

## Primary Architecture

```mermaid
flowchart TD
    %% Presentation Layer
    subgraph UI["SwiftUI Views"]
        SwiftUIViews["SwiftUI Views"]
    end
    
    %% Orchestration Layer
    subgraph Orchestration["@MainActor Layer"]
        GameViewModel[GameViewModel<br/>UI Orchestration]
        AppState[AppState<br/>App Readiness]
        WordPairProvider[WordPairProvider<br/>Prepared Word-Pair Cache]
    end
    
    %% Domain Layer
    subgraph Domain["Pure Game Logic"]
        GameStateMachine[GameStateMachine<br/>Deterministic FSM]
        GameEngine[GameEngine<br/>Stateless Game Rules]
    end
    
    %% Content Generation Layer
    subgraph Content["Content Generation (Actors)"]
        WordGenSvc[WordGeneratorService<br/>Generator Coordination]
        LocalGen[LocalWordGenerator<br/>Offline, Deterministic]
        LLMGen[FoundationModelsWordGenerator<br/>On-device AI]
        TopicSvc[TopicService<br/>Topic Management]
        LocalProv[LocalTopicProvider<br/>words.json]
        LLMPProv[FoundationModelsTopicProvider<br/>AI Generated]
    end
    
    %% Data Infrastructure Layer
    subgraph Infrastructure["Data Infrastructure"]
        WordRepo[WordRepository<br/>Central Word Data]
        PlayedStore[PlayedPairStore<br/>Used Concept Tracking]
        Normalization[Normalization Utility<br/>Concept Identity]
    end
    
    %% Cross-Cutting Concerns
    subgraph Localization["Localization System"]
        AppLanguage[AppLanguage Enum<br/>en, fr, ar, es, tn]
        AppStrings[AppStrings<br/>Localized Strings]
    end
    
    subgraph DesignSystem["Design System"]
        DesignSystem["Design System"]
    end
    
    %% Connections
    %% Presentation to Orchestration
    GameViewModel -->|@Published state| SwiftUIViews
    SwiftUIViews -->|User actions| GameViewModel
    
    %% Orchestration to Domain
    GameViewModel -->|Sync state| GameStateMachine
    GameStateMachine -->|State changes| GameViewModel
    GameViewModel -->|Delegates| GameEngine
    GameEngine -->|Results| GameViewModel
    
    %% Orchestration to Content Generation
    GameViewModel -->|Prepare words| WordPairProvider
    WordPairProvider -->|Requests| WordGenSvc
    WordGenSvc -->|Local generator| LocalGen
    WordGenSvc -->|Foundation Models generator| LLMGen
    
    %% Application Startup Flow
    AppState -->|Owns| TopicSvc
    TopicSvc -->|Local topics| LocalProv
    TopicSvc -->|AI topics| LLMPProv
    LocalProv -->|Topics from| WordRepo
    LLMPProv -->|Generate via| FoundationModels[Foundation Models<br/>Language Model Session]
    TopicSvc -->|Merge topics| CachedTopics[Cached Topics<br/>[GameTopic]]
    TopicSvc -->|Return topics| AppState
    
    %% Word Generation Details
    WordPairProvider -->|Tracks| PlayedStore
    LocalGen -->|Uses| WordRepo
    WordRepo -->|Access| words_json
    WordRepo -->|Uses| Normalization
    PlayedStore -->|Tracks| UsedConcepts[Used Concepts Set]
    
    %% Cross-cutting
    AppLanguage -->|Provides| AppStrings
    AppStrings -->|Used by| SwiftUIViews
    AppLanguage -->|Used by| WordRepo
    AppLanguage -->|Used by| LocalGen
    AppLanguage -->|Used by| LLMGen
    AppLanguage -->|Used by| GameEngine
    DesignSystem -.->|Used by| SwiftUIViews
    
    %% Styling
    classDef mainActor fill:#dbeafe,stroke:#2563eb,stroke-width:2px;
    classDef actor fill:#ede9fe,stroke:#7c3aed,stroke-width:2px;
    classDef domain fill:#fed7aa,stroke:#ea580c,stroke-width:2px;
    classDef infrastructure fill:#dcfce7,stroke:#16a34a,stroke-width:2px;
    classDef localization fill:#fef3c7,stroke:#d97706,stroke-width:2px;
    classDef design fill:#f0f9ff,stroke:#0ea5e9,stroke-width:2px;
    
    class GameViewModel,AppState,WordPairProvider mainActor;
    class WordGenSvc,LocalGen,LLMGen,TopicSvc,LocalProv,LLMPProv actor;
    class GameStateMachine,GameEngine domain;
    class WordRepo,PlayedStore,words_json,Normalization infrastructure;
    class AppLanguage,AppStrings localization;
    class DesignSystem design;
```

### Architecture Explanation

The app separates UI orchestration, deterministic game rules, content preparation, and application startup. `GameViewModel` coordinates gameplay through the pure `GameStateMachine` and `GameEngine`, while `AppState` coordinates topic preparation through `TopicService`. Word-pair preparation uses an actor-based generator system with a prepared cache managed by `WordPairProvider`.