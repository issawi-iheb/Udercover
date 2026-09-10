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

        // Read MainActor-isolated state before #expect
        let isReady = appState.isReady

        // Then
        #expect(isReady == true)
    }

    @Test
    func bootstrap_populatesTopicsFromTopicService() async {
        // Given
        let appState = AppState()

        // When
        await appState.bootstrap()

        // Read MainActor-isolated state before #expect
        let topics = appState.topics
        let hasAnimals = topics.contains { $0.name == "Animals" }
        let hasFruits = topics.contains { $0.name == "Fruits" }
        // Then
        #expect(!topics.isEmpty)
        #expect(hasAnimals)
        #expect(hasFruits)
        #expect(topics.count == 35)
    }

    @Test
    func bootstrap_isIdempotent() async {
        // Given
        let appState = AppState()

        // When
        await appState.bootstrap()
        await appState.bootstrap()

        // Read MainActor-isolated state before #expect
        let isReady = appState.isReady
        let topics = appState.topics

        // Then
        #expect(isReady == true)
        #expect(!topics.isEmpty)
        #expect(topics.count == 35)
    }
}
