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

    private let topicService = TopicService()


    public func bootstrap() async {

        guard !isReady else { return }

        topics = await topicService.topics()

        isReady = true
    }
}
