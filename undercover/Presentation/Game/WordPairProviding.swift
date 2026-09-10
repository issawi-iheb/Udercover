//
//  WordPairProviding.swift
//  undercover
//
//  Created by Iheb on 10/09/2026.
//

import Foundation

@MainActor
protocol WordPairProviding: AnyObject {
    func prepareIfNeeded(
        playerCount: Int,
        topic: String?,
        language: AppLanguage,
        difficulty: PairDifficulty
    )

    func nextPair(
        playerCount: Int,
        topic: String,
        language: AppLanguage,
        difficulty: PairDifficulty
    ) async throws -> WordPair

    func reset()
}
