//
//  PhaseTransitions.swift
//  undercoverApp
//
//  Each game phase has a distinct transition character.
//  Import this and use named transitions in GameRootView.
//

import SwiftUI

extension AnyTransition {

    /// Reveal → Discussion: door opening upward
    static let doorOpen: AnyTransition = .asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal:   .move(edge: .top).combined(with: .opacity)
    )

    /// Discussion → Voting: gavel coming down (snap in from top)
    static let gavelDown: AnyTransition = .asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal:   .move(edge: .bottom).combined(with: .opacity)
    )

    /// Voting → Results: dramatic zoom verdict
    static let verdict: AnyTransition = .asymmetric(
        insertion: .scale(scale: 0.85).combined(with: .opacity),
        removal:   .scale(scale: 1.1).combined(with: .opacity)
    )

    /// Reveal card slide
    static let cardSlide: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal:   .move(edge: .leading).combined(with: .opacity)
    )

    /// Mr. White entrance — rises from bottom with menace
    static let mrWhiteEntrance: AnyTransition = .asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal:   .opacity
    )
}

// MARK: - Animation curves

extension Animation {
    /// Standard spring for most UI interactions
    static let appSpring = Animation.spring(response: 0.42, dampingFraction: 0.78)

    /// Snappy for immediate feedback (button taps)
    static let appSnap = Animation.spring(response: 0.28, dampingFraction: 0.72)

    /// Slow dramatic for results / big moments
    static let appDramatic = Animation.spring(response: 0.7, dampingFraction: 0.65)

    /// Card flip — smooth easeInOut
    static let cardFlip = Animation.easeInOut(duration: 0.45)

    /// Countdown number change
    static let timerTick = Animation.easeOut(duration: 0.15)
}
