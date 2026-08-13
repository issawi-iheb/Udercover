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

    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Circle()
                .fill(isMrWhite ? Color.brandPink.opacity(0.10) : Color.brandPurple.opacity(0.10))
                .frame(width: 340).blur(radius: 90).offset(y: -140)

            VStack(spacing: 0) {
                progressHeader.padding(.horizontal, 24).padding(.top, 16)
                Spacer()
                Group {
                    if step == .passDevice { passContent.transition(slideTransition) }
                    else                   { wordContent.transition(slideTransition) }
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.78), value: step)
                Spacer()
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
    }

    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("REVEAL")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.brandPurple).tracking(3)
                Spacer()
                Text("\(currentIndex + 1) / \(totalPlayers)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 3)
                    Capsule().fill(LinearGradient.brandGlow)
                        .frame(
                            width: geo.size.width * max(Double(currentIndex + 1) / Double(totalPlayers), 0.06),
                            height: 3
                        )
                        .animation(.spring(), value: currentIndex)
                }
            }.frame(height: 3)
        }
    }

    // MARK: - Pass device

    private var passContent: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle().fill(Color.brandPurple.opacity(0.12)).frame(width: 96, height: 96)
                Circle().strokeBorder(Color.brandPurple.opacity(0.2), lineWidth: 1).frame(width: 112, height: 112)
                Image(systemName: "iphone.gen3").font(.system(size: 38))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.brandPurple, Color.brandPink],
                        startPoint: .top, endPoint: .bottom
                    ))
            }
            VStack(spacing: 8) {
                Text(loc("Pass the device to", ar: "مرر الجهاز إلى"))
                    .font(.system(size: 15)).foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                Text(player.name)
                    .font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(.white)
                    .minimumScaleFactor(0.6).lineLimit(1).padding(.horizontal, 24)
            }
            Text(loc("Only you should see your word.", ar: "فقط أنت يجب أن ترى كلمتك."))
                .font(.system(size: 13)).foregroundStyle(Color.white.opacity(0.35))
                .multilineTextAlignment(.center).padding(.horizontal, 40)

            Button(action: onReveal) {
                Label(loc("REVEAL MY WORD", ar: "اكشف كلمتي"), systemImage: "eye.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).tracking(1)
                    .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 17)
                    .background(LinearGradient.brandGlow)
                    .clipShape(RoundedRectangle(cornerRadius: 16)).glow(color: .brandPurple)
            }.padding(.horizontal, 36)
        }
    }

    // MARK: - Show word

    private var wordContent: some View {
        VStack(spacing: 24) {
            Text(player.name)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))

            VStack(spacing: 10) {
                if isMrWhite {
                    Text("MR. WHITE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.brandPink.opacity(0.8)).tracking(3)
                        .rotationEffect(.degrees(180))
                    Text("🃏").font(.system(size: 52)).rotationEffect(.degrees(180))
                    Text("No word — bluff your way through!")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.brandPink.opacity(0.75)).multilineTextAlignment(.center)
                        .rotationEffect(.degrees(180))
                } else {
                    Text(loc("YOUR WORD", ar: "كلمتك"))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.brandPurple.opacity(0.8)).tracking(3)
                        .rotationEffect(.degrees(180))
                    Text(word)
                        .font(.system(size: 50, weight: .black, design: .rounded)).foregroundStyle(.white)
                        .minimumScaleFactor(0.4).lineLimit(1).padding(.horizontal, 12)
                        .rotationEffect(.degrees(180))
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 36).padding(.horizontal, 24)
            .background(Color.appSurface).clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(
                LinearGradient(
                    colors: isMrWhite
                        ? [Color.brandPink.opacity(0.5), Color.brandPurple.opacity(0.35)]
                        : [Color.brandPurple.opacity(0.5), Color.brandPink.opacity(0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ), lineWidth: 1.5
            ))
            .shadow(color: (isMrWhite ? Color.brandPink : Color.brandPurple).opacity(0.18), radius: 24)
            .padding(.horizontal, 24)

            if !isMrWhite {
                Text(loc(
                    "Shown upside-down for privacy — rotate phone to read 🙈",
                    ar: "الكلمة مقلوبة للخصوصية — اعكس الهاتف للقراءة 🙈"
                ))
                .font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.3))
                .multilineTextAlignment(.center).padding(.horizontal, 44)
            }

            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text(loc("HIDE & PASS", ar: "أخفِ وأعطِ"))
                        .font(.system(size: 16, weight: .bold, design: .rounded)).tracking(1)
                    Image(systemName: "arrow.right").font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(LinearGradient.dangerGlow)
                .clipShape(RoundedRectangle(cornerRadius: 16)).glow(color: .brandPink)
            }.padding(.horizontal, 36)
        }
    }

    private func loc(_ en: String, ar: String) -> String { language == .arabic ? ar : en }
}
