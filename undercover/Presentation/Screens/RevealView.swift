//
//  RevealView.swift
//  undercoverApp
//

import SwiftUI

public struct RevealView: View {
    let player: Player
    let word: String
    let role: PlayerRole
    let step: RevealStep
    let totalPlayers: Int
    let currentIndex: Int
    let language: AppLanguage
    let onReveal: () -> Void
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isMrWhite: Bool {
        role == .mrWhite
    }

    private var accentColor: Color {
        isMrWhite ? .brandPink : .brandPurple
    }

    private var strings: AppStrings {
        AppStrings(language: language)
    }

    public var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            // Decorative ambient glow
            RadialGradient.spotlight(color: accentColor, radius: 280)
                .offset(y: -120)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, Space.pagePadding)
                    .padding(.top, Space.md)

                Spacer()

                Group {
                    if step == .passDevice {
                        passContent
                            .transition(reduceMotion ? .opacity : .cardSlide)
                    } else {
                        wordContent
                            .transition(reduceMotion ? .opacity : .cardSlide)
                    }
                }
                .id(player.id)
                .animation(
                    reduceMotion ? .none : .appSpring,
                    value: step
                )

                Spacer()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text(strings.reveal)
                    .font(AppFont.label())
                    .foregroundStyle(Color.brandPurple)
                    .tracking(3)
                    .accessibilityHidden(true)

                Spacer()

                Text("\(currentIndex + 1) / \(totalPlayers)")
                    .font(AppFont.label(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .accessibilityHidden(true)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 3)
                        .accessibilityHidden(true)

                    Capsule()
                        .fill(LinearGradient.brandGlow)
                        .frame(
                            width: geo.size.width
                                * max(
                                    Double(currentIndex + 1)
                                        / Double(totalPlayers),
                                    0.04
                                ),
                            height: 3
                        )
                        .animation(
                            reduceMotion ? .none : .appSpring,
                            value: currentIndex
                        )
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 3)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            strings.revealProgress(
                currentIndex + 1,
                totalPlayers
            )
        )
    }

    // MARK: - Pass device

    private var passContent: some View {
        VStack(spacing: Space.xl) {

            // Decorative device animation
            ZStack {
                PulsingRing(color: accentColor, size: 130)
                    .accessibilityHidden(true)

                PulsingRing(color: accentColor, size: 110)
                    .opacity(0.5)
                    .accessibilityHidden(true)

                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 90, height: 90)
                    .accessibilityHidden(true)

                Image(systemName: "iphone.gen3")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                accentColor,
                                accentColor.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .accessibilityHidden(true)
            }
            .padding(.bottom, Space.sm)
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(strings.passDevice)
                    .font(AppFont.body(size: 16))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(strings.passDevice)

                Text(player.name)
                    .font(AppFont.playerName(size: 44))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, Space.pagePadding)
            }

            Text(strings.onlyYouShouldSeeYourWord)
                .font(AppFont.body(size: 14))
                .foregroundStyle(Color.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.xl)

            // Reveal button
            Button {
                Haptic.cardFlip()
                onReveal()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 17, weight: .bold))
                        .accessibilityHidden(true)

                    Text(strings.revealMyWord)
                        .font(AppFont.button(size: 16))
                        .tracking(1.5)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(LinearGradient.brandGlow)
                .clipShape(
                    RoundedRectangle(cornerRadius: Radius.md)
                )
                .glow(color: accentColor)
            }
            .padding(.horizontal, Space.xl)
            .buttonStyle(
                PartyButtonStyle(
                    gradient: .brandGlow,
                    glowColor: accentColor,
                    disabled: false
                )
            )
            .accessibilityLabel(strings.revealMyWord)
        }
    }

    // MARK: - Show word

    private var wordContent: some View {
        VStack(spacing: Space.lg) {
            Text(player.name)
                .font(AppFont.body(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))

            FlippingWordCard(
                word: word,
                isMrWhite: isMrWhite,
                language: language
            )
            .padding(.horizontal, Space.pagePadding)

            if !isMrWhite {
                Text(strings.shownUpsideDownForPrivacy)
                    .font(AppFont.body(size: 12))
                    .foregroundStyle(Color.white.opacity(0.28))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.xl)
            }

            // Hold-to-confirm hides the word safely
            HoldToConfirmButton(
                label: strings.hideAndPass,
                icon: "eye.slash.fill",
                duration: 0.8,
                color: .brandPink,
                action: {
                    Haptic.cardFlip()
                    onNext()
                }
            )
            .id(player.id)
            .padding(.horizontal, Space.xl)
        }
    }
}

// MARK: - FlippingWordCard

private struct FlippingWordCard: View {
    let word: String
    let isMrWhite: Bool
    let language: AppLanguage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rotation: Double = 0

    private var accentColor: Color {
        isMrWhite ? .brandPink : .brandPurple
    }

    private var strings: AppStrings {
        AppStrings(language: language)
    }

    private var accessibilityLabel: String {
        if isMrWhite {
            return "\(strings.mrWhite). \(strings.mrWhiteDescription)"
        }

        return strings.yourWordIs(word)
    }

    var body: some View {
        ZStack {
            // BACK — purely visual
            cardBack
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(rotation < 90 ? 1 : 0)
                .accessibilityHidden(true)

            // FRONT — purely visual
            cardFront
                .rotation3DEffect(
                    .degrees(rotation - 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(rotation >= 90 ? 1 : 0)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)

        // VoiceOver gets one stable semantic element instead
        // of trying to interpret both sides of the 3D card.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            revealCard()
        }
    }

    private func revealCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if reduceMotion {
                rotation = 180
            } else {
                withAnimation(.cardFlip) {
                    rotation = 180
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                Haptic.wordRevealed()
            }
        }
    }

    // MARK: - Card back

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.appSurface2)

            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    accentColor.opacity(0.3),
                    lineWidth: 1.5
                )

            VStack(spacing: 12) {
                Image(systemName: "questionmark")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(accentColor.opacity(0.4))
                    .accessibilityHidden(true)

                Text(strings.tapToReveal)
                    .font(AppFont.label(size: 10))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .tracking(2)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Card front

    private var cardFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(
                    isMrWhite
                        ? Color(hex: "#1A1A2E")
                        : Color.appSurface2
                )

            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: isMrWhite
                            ? [
                                Color.brandPink.opacity(0.6),
                                Color.brandPurple.opacity(0.4)
                            ]
                            : [
                                Color.brandPurple.opacity(0.6),
                                Color.brandPink.opacity(0.4)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(
                    color: accentColor.opacity(0.2),
                    radius: 20
                )

            VStack(spacing: 14) {
                if isMrWhite {
                    mrWhiteContent
                } else {
                    civilianContent
                }
            }
            .rotationEffect(.degrees(180))
        }
    }

    // MARK: - Civilian content

    private var civilianContent: some View {
        VStack(spacing: 14) {
            Text(strings.yourWord)
                .font(AppFont.label(size: 11))
                .foregroundStyle(Color.brandPurple.opacity(0.7))
                .tracking(3)
                .accessibilityHidden(true)

            Text(word)
                .font(AppFont.gameWord(size: 65))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.35)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.md)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Mr. White content

    private var mrWhiteContent: some View {
        VStack(spacing: 12) {
            Text(strings.mrWhite)
                .font(AppFont.label(size: 12))
                .foregroundStyle(Color.brandPink.opacity(0.8))
                .tracking(4)
                .accessibilityHidden(true)

            Text("🃏")
                .font(.system(size: 52))
                .accessibilityHidden(true)

            Text(strings.mrWhiteBluffMessage)
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundStyle(Color.brandPink.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.lg)
                .accessibilityHidden(true)
        }
    }
}
