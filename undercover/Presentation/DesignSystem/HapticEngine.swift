//
//  HapticEngine.swift
//  undercoverApp
//
//  Choreographed haptics. Every game moment has a distinct pattern.
//  Never use UIImpactFeedbackGenerator directly — go through here.
//

import UIKit

enum Haptic {

    // MARK: - Basic

    static func light()   { impact(.light) }
    static func medium()  { impact(.medium) }
    static func heavy()   { impact(.heavy) }
    static func success() { notify(.success) }
    static func warning() { notify(.warning) }
    static func error()   { notify(.error) }

    // MARK: - Game moments

    /// Card flip landing — soft thud
    static func cardFlip() {
        impact(.rigid)
    }

    /// Word revealed — medium impact + soft follow
    static func wordRevealed() {
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            impact(.soft)
        }
    }

    /// Player added to lobby — light pop
    static func playerAdded() {
        impact(.light)
    }

    /// Vote cast — heavy commitment
    static func voteCast() {
        impact(.heavy)
    }

    /// Vote confirmed / player eliminated — triple heavy
    static func playerEliminated() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { impact(.heavy) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { impact(.medium) }
    }

    /// Civilians win — success + celebration burst
    static func civiliansWin() {
        notify(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { impact(.light) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { impact(.light) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { impact(.medium) }
    }

    /// Undercover wins — sinister double
    static func undercoverWins() {
        notify(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { impact(.heavy) }
    }

    /// Mr. White wins — magician flourish
    static func mrWhiteWins() {
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { impact(.medium) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { impact(.heavy) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) { notify(.success) }
    }

    /// Mr. White wrong guess — sad thud
    static func mrWhiteWrongGuess() {
        notify(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { impact(.heavy) }
    }

    /// Timer warning — tick at ≤10s
    static func timerTick() {
        impact(.light)
    }

    /// Timer expired — urgent
    static func timerExpired() {
        notify(.warning)
    }

    /// Hold progress — rhythmic pulse
    static func holdPulse() {
        impact(.soft)
    }

    // MARK: - Private

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
