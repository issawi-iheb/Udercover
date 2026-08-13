//
//  GameRootView.swift
//  undercoverApp
//
//  Single switch on gameState drives all screen routing.
//  No phase logic lives anywhere else.
//

import SwiftUI

public struct GameRootView: View {
    @ObservedObject public var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        ZStack {
            LinearGradient.brandBackground.ignoresSafeArea()

            Group {
                switch viewModel.gameState {

                case .setup, .loadingWords:
                    loadingScreen

                case .reveal:
                    if let player = viewModel.currentRevealingPlayer() {
                        RevealView(
                            player:       player,
                            word:         viewModel.word(for: player),
                            role:         viewModel.role(for: player),
                            step:         viewModel.currentRevealStep,
                            totalPlayers: viewModel.revealOrder.count,
                            currentIndex: viewModel.currentRevealIndex,
                            language:     viewModel.selectedLanguage,
                            onReveal:     { viewModel.revealTapped() },
                            onNext:       { viewModel.revealNext() }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                    }

                case .discussion(let round):
                    DiscussionView(round: round, viewModel: viewModel)
                        .transition(.opacity)
                        .onAppear { viewModel.startDiscussionTimer(seconds: 60) }

                case .voting:
                    VotingView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                case .mrWhiteGuess:
                    MrWhiteGuessView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                case .results(let result):
                    ResultsView(
                        result:    result,
                        viewModel: viewModel,
                        onReplay:  { Task { await viewModel.replay() } },
                        onNewGame: { viewModel.newGame(); dismiss() }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: viewModel.gameState)
        }
    }

    private var loadingScreen: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.4).tint(Color.brandPurple)
            Text("Generating words…")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }
}
