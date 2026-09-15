//
//  AppStateTests.swift
//  undercoverTests
//

import Testing
@testable import undercover

@MainActor
struct AppStateTests {

    @Test
    func bootstrap_setsIsReadyToTrue() async {
        // Given
        let appState = AppState()

        // When
        await appState.bootstrap()

        // Then
        let isReady = appState.isReady

        #expect(isReady == true)
    }

    @Test
    func bootstrap_populatesTopicsFromTopicService() async {
        // Given
        let appState = AppState()

        // When
        await appState.bootstrap()

        // Then
        let topics = appState.topics
        let hasAnimals = topics.contains {
            $0.name == "Animals"
        }

        #expect(!topics.isEmpty)
        #expect(hasAnimals)
    }

    @Test
    func bootstrap_isIdempotent() async {
        // Given
        let appState = AppState()

        // When
        await appState.bootstrap()
        await appState.bootstrap()

        // Then
        let isReady = appState.isReady
        let topics = appState.topics

        #expect(isReady == true)
        #expect(!topics.isEmpty)
    }
}
