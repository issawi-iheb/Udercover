//
//  ResultsView.swift
//  undercoverApp
//

import SwiftUI

public struct ResultsView: View {
    let result:    GameResult
    @ObservedObject var viewModel: GameViewModel
    let onReplay:  () -> Void
    let onNewGame: () -> Void

    @State private var appeared      = false
    @State private var particlesOn   = false
    @State private var cardFlipped   = false

    private var s: AppStrings { viewModel.selectedLanguage.strings }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                // Themed background
                themedBackground(geo: geo)

                // Particles
                particleLayer

                // Content
                VStack(spacing: 0) {
                    Spacer(minLength: 30)

                    // Emoji + title
                    VStack(spacing: 16) {
                        Text(result.emoji)
                            .font(.system(size: 80))
                            .scaleEffect(appeared ? 1 : 0.1)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: appeared)

                        Text(result.title.uppercased())
                            .font(.system(size: 32,
                                          weight: .black, design: .rounded))
                            .foregroundStyle(result.color)
                            .multilineTextAlignment(.center)
                            .shadow(color: result.color.opacity(0.6), radius: 18)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(.appDramatic.delay(0.28), value: appeared)
                    }

                    Spacer(minLength: Space.lg)

                    // Flipping reveal card
                    ResultRevealCard(
                        result:        result,
                        viewModel:     viewModel,
                        isFlipped:     cardFlipped,
                        strings:       s
                    )
                    .padding(.horizontal, Space.pagePadding)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 32)
                    .animation(.appDramatic.delay(0.44), value: appeared)

                    Spacer(minLength: Space.lg)

                    // Buttons
                    actionButtons
                        .padding(.horizontal, Space.pagePadding)
                        .padding(.bottom, geo.safeAreaInsets.bottom + Space.md)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.appDramatic.delay(0.58), value: appeared)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear {
            appeared = true
            // Stagger particle burst and card flip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                particlesOn = true
                triggerHaptic()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.cardFlip) { cardFlipped = true }
            }
        }
        .environment(\.layoutDirection, viewModel.selectedLanguage.layoutDirection)
    }

    // MARK: - Themed background

    @ViewBuilder
    private func themedBackground(geo: GeometryProxy) -> some View {
        switch result {
        case .civiliansWin:
            // Warm green celebration
            RadialGradient(
                colors: [Color.accentGreen.opacity(0.25), .clear],
                center: .top, startRadius: 0, endRadius: geo.size.height
            ).ignoresSafeArea()

        case .undercoverWins:
            // Dark sinister — single spotlight from below
            RadialGradient(
                colors: [Color.brandPink.opacity(0.30), .clear],
                center: .bottom, startRadius: 0, endRadius: geo.size.height
            ).ignoresSafeArea()

        case .mrWhiteWins:
            // White/purple ethereal
            RadialGradient(
                colors: [Color.brandPurple.opacity(0.28), .clear],
                center: .center, startRadius: 0, endRadius: geo.size.height * 0.8
            ).ignoresSafeArea()
        }
    }

    // MARK: - Particle layer

    @ViewBuilder
    private var particleLayer: some View {
        switch result {
        case .civiliansWin:
            ConfettiView(active: particlesOn)
        case .undercoverWins:
            SmokeParticleView(active: particlesOn)
        case .mrWhiteWins:
            SparkleView(active: particlesOn)
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Haptic.heavy()
                onReplay()
            } label: {
                Group {
                    if viewModel.isGeneratingWords {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text(s.generatingWords).font(AppFont.button(size: 16))
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 15, weight: .bold))
                            Text(s.replaySameTeam).font(AppFont.button())
                        }
                    }
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(LinearGradient.brandGlow)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .glow(color: .brandPurple)
            }
            .disabled(viewModel.isGeneratingWords)

            Button {
                Haptic.medium()
                onNewGame()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                    Text(s.newGame).font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(Color.appBorder, lineWidth: 1))
            }
        }
    }

    private func triggerHaptic() {
        switch result {
        case .civiliansWin:   Haptic.civiliansWin()
        case .undercoverWins: Haptic.undercoverWins()
        case .mrWhiteWins:    Haptic.mrWhiteWins()
        }
    }
}

// MARK: ─── GameResult color ───────────────────────────────────────────────────

extension GameResult {
    public var color: Color {
        switch self {
        case .civiliansWin:   return .accentGreen
        case .undercoverWins: return .brandPink
        case .mrWhiteWins:    return .brandPurple
        }
    }
}

// MARK: ─── ResultRevealCard ───────────────────────────────────────────────────
// A card that starts face-down (shows "?") then flips to reveal the role + word pair.

private struct ResultRevealCard: View {
    let result:    GameResult
    let viewModel: GameViewModel
    let isFlipped: Bool
    let strings:   AppStrings

    var body: some View {
        CardFlip3D(
            isFlipped: isFlipped,
            front: {
                // Back face — mystery
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.card).fill(Color.appSurface2)
                    RoundedRectangle(cornerRadius: Radius.card)
                        .strokeBorder(result.color.opacity(0.3), lineWidth: 1.5)
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark")
                            .font(.system(size: 40, weight: .black))
                            .foregroundStyle(result.color.opacity(0.4))
                        Text("TAP TO REVEAL")
                            .font(AppFont.label(size: 10))
                            .foregroundStyle(Color.white.opacity(0.2)).tracking(2)
                    }
                }
                .frame(height: 180)
            },
            back: {
                // Front face — the reveal
                revealContent.frame(height: 180)
            },
            onFlipMid: { Haptic.cardFlip() }
        )
    }

    private var revealContent: some View {
        VStack(spacing: 16) {
            // Who was the undercover / mr white
            roleRows

            Divider().background(Color.appBorder)

            // Word pair
            HStack(alignment: .top) {
                WordLabel(title: strings.civilians,
                          word:  viewModel.currentCivilianWord,
                          color: .accentGreen)
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .padding(.top, 18)
                Spacer()
                WordLabel(title: strings.undercover,
                          word:  viewModel.currentUndercoverWord,
                          color: .brandPink)
            }
        }
        .padding(Space.lg)
        .glassCard(cornerRadius: Radius.card)
    }

    @ViewBuilder
    private var roleRows: some View {
        if let uc = viewModel.undercoverPlayer() {
            roleRow(icon: "😈", label: strings.theUndercoverWas, name: uc.name, color: .brandPink)
        }
        if let mw = viewModel.mrWhitePlayer() {
            roleRow(icon: "🃏", label: "MR. WHITE WAS", name: mw.name, color: .brandPurple)
        }
    }

    private func roleRow(icon: String, label: String, name: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(icon).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.label(size: 9))
                    .foregroundStyle(Color.white.opacity(0.35)).tracking(2)
                Text(name)
                    .font(AppFont.playerName(size: 20))
                    .foregroundStyle(color)
            }
            Spacer()
        }
    }
}
