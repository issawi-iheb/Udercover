//
//  RevealView.swift
//  undercoverApp
//

import SwiftUI

public struct RevealView: View {
    let player:       Player
    let word:         String
    let role:         PlayerRole
    let step:         RevealStep
    let totalPlayers: Int
    let currentIndex: Int
    let language:     AppLanguage
    let onReveal:     () -> Void
    let onNext:       () -> Void

    private var isMrWhite: Bool { role == .mrWhite }
    private var accentColor: Color { isMrWhite ? .brandPink : .brandPurple }

    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Ambient glow — color reflects role
            RadialGradient.spotlight(color: accentColor, radius: 280)
                .offset(y: -120)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, Space.pagePadding)
                    .padding(.top, Space.md)

                Spacer()

                Group {
                    if step == .passDevice {
                        passContent.transition(.cardSlide)
                    } else {
                        wordContent.transition(.cardSlide)
                    }
                }
                .animation(.appSpring, value: step)

                Spacer()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("REVEAL")
                    .font(AppFont.label()).foregroundStyle(Color.brandPurple).tracking(3)
                Spacer()
                Text("\(currentIndex + 1) / \(totalPlayers)")
                    .font(AppFont.label(size: 13)).foregroundStyle(Color.white.opacity(0.4))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07)).frame(height: 3)
                    Capsule().fill(LinearGradient.brandGlow)
                        .frame(
                            width: geo.size.width * max(Double(currentIndex + 1) / Double(totalPlayers), 0.04),
                            height: 3
                        )
                        .animation(.appSpring, value: currentIndex)
                }
            }.frame(height: 3)
        }
    }

    // MARK: - Pass device

    private var passContent: some View {
        VStack(spacing: Space.xl) {

            // Pulsing device icon with rings
            ZStack {
                PulsingRing(color: accentColor, size: 130)
                PulsingRing(color: accentColor, size: 110)
                    .opacity(0.5)

                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 90, height: 90)

                Image(systemName: "iphone.gen3")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [accentColor, accentColor.opacity(0.6)],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
            .padding(.bottom, Space.sm)

            VStack(spacing: 10) {
                Text(loc("Pass the device to", ar: "مرر الجهاز إلى"))
                    .font(AppFont.body(size: 16))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                Text(player.name)
                    .font(AppFont.playerName(size: 44))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, Space.pagePadding)
            }

            Text(loc("Only you should see your word.", ar: "فقط أنت يجب أن ترى كلمتك."))
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
                    Text(loc("REVEAL MY WORD", ar: "اكشف كلمتي"))
                        .font(AppFont.button(size: 16)).tracking(1.5)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(LinearGradient.brandGlow)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .glow(color: accentColor)
            }
            .padding(.horizontal, Space.xl)
            .buttonStyle(PartyButtonStyle(gradient: .brandGlow, glowColor: accentColor, disabled: false))
        }
    }

    // MARK: - Show word (3D flip card)

    private var wordContent: some View {
        VStack(spacing: Space.lg) {

            Text(player.name)
                .font(AppFont.body(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))

            // The card — flips in on appear
            FlippingWordCard(
                word:      word,
                isMrWhite: isMrWhite,
                language:  language
            )
            .padding(.horizontal, Space.pagePadding)

            if !isMrWhite {
                Text(loc(
                    "Shown upside-down for privacy — rotate to read 🙈",
                    ar: "الكلمة مقلوبة للخصوصية — اعكس الهاتف للقراءة 🙈"
                ))
                .font(AppFont.body(size: 12))
                .foregroundStyle(Color.white.opacity(0.28))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.xl)
            }

            // Hold-to-confirm hides the word safely
            HoldToConfirmButton(
                label:    loc("HIDE & PASS", ar: "أخفِ وأعطِ"),
                icon:     "eye.slash.fill",
                duration: 0.8,
                color:    .brandPink,
                action:   {
                    Haptic.cardFlip()
                    onNext()
                }
            )
            .padding(.horizontal, Space.xl)
        }
    }

    private func loc(_ en: String, ar: String) -> String {
        language == .arabic ? ar : en
    }
}

// MARK: ─── FlippingWordCard ───────────────────────────────────────────────────

private struct FlippingWordCard: View {
    let word:      String
    let isMrWhite: Bool
    let language:  AppLanguage

    @State private var isFlipped = false
    @State private var rotation: Double = 0

    private var accentColor: Color { isMrWhite ? .brandPink : .brandPurple }

    var body: some View {
        ZStack {
            // BACK — question mark (shown before flip)
            cardBack
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                .opacity(rotation < 90 ? 1 : 0)

            // FRONT — the word (shown after flip, upside-down for privacy)
            cardFront
                .rotation3DEffect(.degrees(rotation - 180), axis: (x: 0, y: 1, z: 0))
                .opacity(rotation >= 90 ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .onAppear {
            // Delay so user sees the back first, then dramatic flip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.cardFlip) { rotation = 180 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    Haptic.wordRevealed()
                }
            }
        }
    }

    // Card back — shown before flip
    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.appSurface2)
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(accentColor.opacity(0.3), lineWidth: 1.5)

            VStack(spacing: 12) {
                Image(systemName: "questionmark")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(accentColor.opacity(0.4))
                Text("TAP TO REVEAL")
                    .font(AppFont.label(size: 10))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .tracking(2)
            }
        }
    }

    // Card front — the word, upside-down
    private var cardFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(isMrWhite ? Color(hex: "#1A1A2E") : Color.appSurface2)
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: isMrWhite
                            ? [Color.brandPink.opacity(0.6), Color.brandPurple.opacity(0.4)]
                            : [Color.brandPurple.opacity(0.6), Color.brandPink.opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            // Shadow for depth
            .shadow(color: accentColor.opacity(0.2), radius: 20)

            VStack(spacing: 14) {
                if isMrWhite {
                    mrWhiteContent
                } else {
                    civilianContent
                }
            }
            .rotationEffect(.degrees(180))  // upside-down for privacy
        }
    }

    private var civilianContent: some View {
        VStack(spacing: 14) {
            Text(language == .arabic ? "كلمتك" : "YOUR WORD")
                .font(AppFont.label(size: 11))
                .foregroundStyle(Color.brandPurple.opacity(0.7))
                .tracking(3)

            Text(word)
                .font(AppFont.gameWord(size: 65))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.35)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.md)
        }
    }

    private var mrWhiteContent: some View {
        VStack(spacing: 12) {
            Text("MR. WHITE")
                .font(AppFont.label(size: 12))
                .foregroundStyle(Color.brandPink.opacity(0.8))
                .tracking(4)

            Text("🃏")
                .font(.system(size: 52))

            Text("No word.\nBluff your way through.")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundStyle(Color.brandPink.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Space.lg)
        }
    }
}
