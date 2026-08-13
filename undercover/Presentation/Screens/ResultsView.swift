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
    @State private var appeared = false
    private var s: AppStrings { viewModel.selectedLanguage.strings }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(result.color.opacity(0.10)).frame(width: 500).blur(radius: 120)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .scaleEffect(appeared ? 1.2 : 0.6)
                    .animation(.easeOut(duration: 1.2), value: appeared)

                VStack(spacing: 0) {
                    Spacer(minLength: 16)

                    VStack(spacing: adaptiveSpacing) {
                        Text(result.emoji)
                            .font(.system(size: adaptiveEmojiSize))
                            .scaleEffect(appeared ? 1 : 0.2).opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.65, dampingFraction: 0.55).delay(0.1), value: appeared)

                        Text(result.title.uppercased())
                            .font(.system(size: adaptiveTitleSize, weight: .black, design: .rounded))
                            .foregroundStyle(result.color).multilineTextAlignment(.center)
                            .shadow(color: result.color.opacity(0.5), radius: 14)
                            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                            .animation(.spring().delay(0.28), value: appeared)

                        revealCard.padding(.horizontal, 24)
                            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 30)
                            .animation(.spring().delay(0.42), value: appeared)
                    }
                    .frame(maxWidth: min(520, geo.size.width)).frame(maxWidth: .infinity)

                    Spacer(minLength: 16)

                    VStack(spacing: 12) {
                        Button {
                            Haptic.heavy(); onReplay()
                        } label: {
                            Group {
                                if viewModel.isGeneratingWords {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.white)
                                        Text(s.generatingWords).font(.system(size: 16, weight: .semibold))
                                    }
                                } else {
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 15, weight: .bold))
                                        Text(s.replaySameTeam).font(.system(size: 17, weight: .bold, design: .rounded))
                                    }
                                }
                            }
                            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(LinearGradient.brandGlow)
                            .clipShape(RoundedRectangle(cornerRadius: 18)).glow(color: .brandPurple)
                        }.disabled(viewModel.isGeneratingWords)

                        Button { Haptic.medium(); onNewGame() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "house.fill"); Text(s.newGame)
                            }
                            .foregroundStyle(Color.white.opacity(0.65)).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Color.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.appBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear { appeared = true }
        .environment(\.layoutDirection, viewModel.selectedLanguage.layoutDirection)
    }

    private var revealCard: some View {
        VStack(spacing: 18) {
            if let uc = viewModel.undercoverPlayer() {
                roleRow(label: s.theUndercoverWas, name: uc.name, icon: "😈")
            }
            if let mw = viewModel.mrWhitePlayer() {
                Rectangle().fill(Color.appBorder).frame(height: 1)
                roleRow(label: "MR. WHITE WAS", name: mw.name, icon: "🃏")
            }
            Rectangle().fill(Color.appBorder).frame(height: 1)
            HStack(alignment: .top) {
                WordLabel(title: s.civilians, word: viewModel.currentCivilianWord, color: .accentGreen)
                Spacer()
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.22)).padding(.top, 18)
                Spacer()
                WordLabel(title: s.undercover, word: viewModel.currentUndercoverWord, color: .brandPink)
            }
        }
        .padding(22).glassCard(cornerRadius: 22)
    }

    private func roleRow(label: String, name: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Text(label).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.38)).tracking(3)
            HStack(spacing: 8) {
                Text(icon)
                Text(name).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(.white)
            }
        }
    }

    private var adaptiveEmojiSize:  CGFloat { UIScreen.main.bounds.height < 700 ? 70 : 88 }
    private var adaptiveTitleSize:  CGFloat { UIScreen.main.bounds.height < 700 ? 26 : 32 }
    private var adaptiveSpacing:    CGFloat { UIScreen.main.bounds.height < 700 ? 12 : 18 }
}

// MARK: - GameResult color

extension GameResult {
    public var color: Color {
        switch self {
        case .civiliansWin:   return .accentGreen
        case .undercoverWins: return .brandPink
        case .mrWhiteWins:    return .brandPurple
        }
    }
}
