//
//  LocalTopicProvider.swift
//  undercover
//
//  Created by Iheb on 14/08/2026.
//

import Foundation

public protocol TopicProvider: Sendable {

    func topics() async -> [String]

}

public actor LocalTopicProvider: TopicProvider {

    private let repository = WordRepository()

    public func topics() async -> [String] {
        repository.topics
    }
}
