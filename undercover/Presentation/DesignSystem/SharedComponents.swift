//
//  SharedComponents.swift
//  undercoverApp
//

import SwiftUI

// MARK: ─── WordLabel ──────────────────────────────────────────────────────────

struct WordLabel: View {
    let title: String
    let word:  String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(AppFont.label(size: 10))
                .foregroundStyle(color.opacity(0.7))
                .tracking(2)
            Text(word)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: ─── RoundBadge ────────────────────────────────────────────────────────

struct RoundBadge: View {
    let round:    Int
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.brandPurple.opacity(0.2)).frame(width: 28, height: 28)
                Image(systemName: "flag.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.brandPurple)
            }
            Text(language.strings.round(round))
                .font(AppFont.body(size: 14, weight: .black))
                .foregroundStyle(.white)
                .tracking(language.isRTL ? 0 : 1.5)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(ZStack {
            Color.appSurface
            LinearGradient.surfaceGlow
        })
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(
            LinearGradient(colors: [Color.brandPurple.opacity(0.5), Color.brandPink.opacity(0.3)],
                           startPoint: .leading, endPoint: .trailing), lineWidth: 1
        ))
        .shadow(color: Color.brandPurple.opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

// MARK: ─── DifficultyBadge ───────────────────────────────────────────────────

struct DifficultyBadge: View {
    let difficulty: PairDifficulty

    var body: some View {
        HStack(spacing: 5) {
            Text(difficulty.emoji).font(.system(size: 12))
            Text(difficulty.label)
                .font(AppFont.label(size: 11))
                .foregroundStyle(difficulty.color)
                .tracking(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(difficulty.color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(difficulty.color.opacity(0.35), lineWidth: 1))
    }
}

// MARK: ─── PlayerChip ─────────────────────────────────────────────────────────
// Small dot showing a player's status. Used in DiscussionView.

struct PlayerChip: View {
    let player:    Player
    let index:     Int
    let isAlive:   Bool

    private var accent: Color { .avatar(for: index) }

    var body: some View {
        ZStack {
            Circle()
                .fill(isAlive ? accent.opacity(0.25) : Color.white.opacity(0.06))
                .frame(width: 36, height: 36)
                .overlay(Circle().strokeBorder(
                    isAlive ? accent.opacity(0.6) : Color.white.opacity(0.1),
                    lineWidth: isAlive ? 1.5 : 1
                ))

            Text(String(player.name.prefix(1)).uppercased())
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(isAlive ? accent : Color.white.opacity(0.2))

            if !isAlive {
                // X overlay for eliminated players
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.brandPink.opacity(0.8))
            }
        }
        .opacity(isAlive ? 1.0 : 0.5)
    }
}

// MARK: ─── ArcTimer ──────────────────────────────────────────────────────────
// Circular arc progress indicator. Replaces raw number-only timer.

 struct ArcTimer: View {
    let progress: Double
    let color: Color
    let timeString: String

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.white.opacity(0.06),
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )

            // Active timer
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .linear(duration: 0.9),
                    value: clampedProgress
                )

            // Time
            Text(timeString)
                .font(
                    .system(
                        size: 56,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: timeString)
        }
    }
}
// MARK: ─── PrimaryButton / SecondaryButton ───────────────────────────────────

struct PrimaryButton: View {
    let label:     String
    let icon:      String?
    let gradient:  LinearGradient
    let glowColor: Color
    let action:    () -> Void

    init(_ label: String, icon: String? = nil,
         gradient: LinearGradient = .brandGlow,
         glowColor: Color = .brandPurple,
         action: @escaping () -> Void) {
        self.label = label; self.icon = icon
        self.gradient = gradient; self.glowColor = glowColor; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .bold)) }
                Text(label).font(AppFont.button()).tracking(1.5)
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(gradient).clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .glow(color: glowColor)
        }
        .buttonStyle(PartyButtonStyle(gradient: gradient, glowColor: glowColor, disabled: false))
    }
}

struct SecondaryButton: View {
    let label:  String
    let icon:   String?
    let action: () -> Void

    init(_ label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label; self.icon = icon; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .bold)) }
                Text(label).font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color.white.opacity(0.65)).frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Color.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Color.appBorder, lineWidth: 1))
        }
    }
}
