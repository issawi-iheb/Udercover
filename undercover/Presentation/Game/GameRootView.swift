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
            Color.appBackground.ignoresSafeArea()

            Group {
                switch viewModel.gameState {

                case .setup, .loadingWords:
                    loadingScreen
                        .transition(.opacity)

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
                        .transition(.cardSlide)
                    }

                case .discussion(let round):
                    DiscussionView(round: round, viewModel: viewModel)
                        .transition(.doorOpen)
                        .onAppear { viewModel.startDiscussionTimer(seconds: Config.discussionTimerSeconds) }

                case .voting:
                    VotingView(viewModel: viewModel)
                        .transition(.gavelDown)

                case .mrWhiteGuess:
                    MrWhiteGuessView(viewModel: viewModel)
                        .transition(.mrWhiteEntrance)

                case .results(let result):
                    ResultsView(
                        result:    result,
                        viewModel: viewModel,
                        onReplay:  { Task { await viewModel.replay() } },
                        onNewGame: {
                            viewModel.newGame()
                            dismiss()
                        }
                    )
                    .transition(.verdict)
                }
            }
            .animation(.appSpring, value: viewModel.gameState)
        }
    }

    // MARK: - Loading screen

    private var loadingScreen: some View {
        VStack(spacing: Space.lg) {
            ZStack {
                PulsingRing(color: .brandPurple, size: 80)
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(Color.brandPurple)
            }
            Text("Finding words…")
                .font(AppFont.body(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }
}
