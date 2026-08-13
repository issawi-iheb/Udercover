//
//  DiscussionView.swift
//  undercoverApp
//

import SwiftUI

public struct DiscussionView: View {
    let round: Int
    @ObservedObject var viewModel: GameViewModel
    @State private var pulse = false

    private var s: AppStrings { viewModel.selectedLanguage.strings }
    private var timerColor: Color {
        viewModel.timeRemaining <= 10 ? .accentRed
            : viewModel.timeRemaining <= 30 ? .accentAmber
            : .white
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(timerColor.opacity(0.07)).frame(width: 480).blur(radius: 100)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .scaleEffect(pulse ? 1.12 : 1.0)
                    .animation(
                        viewModel.timeRemaining <= 10
                            ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                            : .default,
                        value: pulse
                    )

                VStack(spacing: 0) {
                    Spacer(minLength: 16)

                    HStack(spacing: 12) {
                        RoundBadge(round: round, language: viewModel.selectedLanguage)
                        DifficultyBadge(difficulty: viewModel.selectedDifficulty)
                    }.padding(.top, 10)

                    Spacer(minLength: 12)

                    VStack(spacing: adaptiveSpacing) {
                        Text(s.discussAndDeduce)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.30))
                            .tracking(viewModel.selectedLanguage.isRTL ? 0 : 3)
                            .multilineTextAlignment(.center)

                        Text("\(viewModel.timeRemaining)")
                            .font(.system(size: adaptiveTimerSize, weight: .black, design: .rounded))
                            .foregroundStyle(timerColor).monospacedDigit()
                            .shadow(color: timerColor.opacity(0.4), radius: 24)
                            .scaleEffect(viewModel.timeRemaining <= 10 && pulse ? 1.06 : 1.0)
                            .animation(.easeInOut, value: viewModel.timeRemaining)

                        Text(s.seconds)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.30))
                    }

                    Spacer(minLength: 12)

                    hintCard.padding(.horizontal, 28).padding(.bottom, 12)

                    Button {
                        Haptic.heavy()
                        viewModel.enterVoting()
                    } label: {
                        Label(s.startVotingNow, systemImage: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .tracking(viewModel.selectedLanguage.isRTL ? 0 : 1)
                            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 17)
                            .background(LinearGradient.brandGlow)
                            .clipShape(RoundedRectangle(cornerRadius: 16)).glow(color: .brandPurple)
                    }
                    .padding(.horizontal, 28).padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear { pulse = true }
        .environment(\.layoutDirection, viewModel.selectedLanguage.layoutDirection)
    }

    private var hintCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill.questionmark").font(.system(size: 22)).foregroundStyle(Color.brandPurple)
            VStack(alignment: .leading, spacing: 3) {
                Text(s.findUndercover)
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text(s.discussClues)
                    .font(.system(size: 13)).foregroundStyle(Color.white.opacity(0.45))
            }
            Spacer()
        }
        .padding(16).glassCard()
    }

    private var adaptiveTimerSize: CGFloat { UIScreen.main.bounds.height < 700 ? 82 : 108 }
    private var adaptiveSpacing:   CGFloat { UIScreen.main.bounds.height < 700 ? 10 : 14 }
}
