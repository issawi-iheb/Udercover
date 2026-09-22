//
//  AppState.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {

    @Published public private(set) var topics: [GameTopic] = []
    @Published public private(set) var isReady = false

    private let topicService: TopicService

    public init() {
        topicService = TopicService(
            providers: [
                LocalTopicProvider(),
                FoundationModelsTopicProvider()
            ]
        )
    }

    public func bootstrap() async {
        guard !isReady else {
            return
        }

        // Wait for local topics.
        topics = await topicService.localTopics()
        isReady = true

        // AI topics load in the background.
        Task {
            let topics = await topicService.loadAITopics()
            self.topics = topics
        }
    }
}
