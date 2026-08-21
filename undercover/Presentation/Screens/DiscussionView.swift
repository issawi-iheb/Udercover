//
//  DiscussionView.swift
//  undercoverApp
//

import SwiftUI

public struct DiscussionView: View {
    let round: Int
    @ObservedObject var viewModel: GameViewModel

    @State private var appeared = false

    private var s: AppStrings {
        viewModel.selectedLanguage.strings
    }

    private var timerProgress: Double {
        guard Config.discussionTimerSeconds > 0 else {
            return 0
        }

        return min(
            max(
                Double(viewModel.timeRemaining) /
                Double(Config.discussionTimerSeconds),
                0
            ),
            1
        )
    }

    private var timerColor: Color {
        if viewModel.timeRemaining <= 10 {
            return .accentRed
        }

        if viewModel.timeRemaining <= 30 {
            return .accentAmber
        }

        return .white
    }

    private var isUrgent: Bool {
        viewModel.timeRemaining <= 10
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: Background

                Color.appBackground
                    .ignoresSafeArea()

                // Central glow
                RadialGradient.spotlight(
                    color: timerColor.opacity(isUrgent ? 0.6 : 0.15),
                    radius: isUrgent ? 320 : 200
                )
                .animation(
                    .easeInOut(duration: 0.8),
                    value: isUrgent
                )
                .allowsHitTesting(false)

                VStack(spacing: 0) {

                    // MARK: Top bar

                    HStack(spacing: 10) {
                        RoundBadge(
                            round: round,
                            language: viewModel.selectedLanguage
                        )

                        DifficultyBadge(
                            difficulty: viewModel.selectedDifficulty
                        )

                        Spacer()
                    }
                    .padding(.horizontal, Space.pagePadding)
                    .padding(
                        .top, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .appSpring.delay(0.1),
                        value: appeared
                    )

                    Spacer()

                    // MARK: Circular timer

                    ZStack {
                        ArcTimer(
                            progress: timerProgress,
                            color: timerColor,
                            timeString: "\(viewModel.timeRemaining)"
                        )
                        .frame(
                            width: ScreenSize.circleSize(for: geo.size.width),
                            height: ScreenSize.circleSize(for: geo.size.width)
                        )
                        // Only show the pulse when urgent.
                        if isUrgent {
                            PulsingRing(
                                color: .accentRed,
                                size: 230
                            )
                            .allowsHitTesting(false)
                        }
                    }
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .appDramatic.delay(0.15),
                        value: appeared
                    )

                    Text(s.seconds)
                        .font(AppFont.label(size: 12))
                        .foregroundStyle(
                            timerColor.opacity(0.5)
                        )
                        .padding(.top, 6)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .appSpring.delay(0.2),
                            value: appeared
                        )

                    Spacer()

                    // MARK: Player status

                    playerChips
                        .padding(.horizontal, Space.pagePadding)
                        .padding(.bottom, Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .appSpring.delay(0.25),
                            value: appeared
                        )

                    // MARK: Hint

                    if round == 1 {
                        hintCard
                            .padding(.horizontal, Space.pagePadding)
                            .padding(.bottom, Space.md)
                            .transition(
                                .move(edge: .bottom)
                                .combined(with: .opacity)
                            )
                    }

                    // MARK: Vote button

                    Button {
                        Haptic.heavy()
                        viewModel.enterVoting()
                    } label: {
                        Label(
                            s.startVotingNow,
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(AppFont.button())
                        .tracking(
                            viewModel.selectedLanguage.isRTL
                            ? 0
                            : 1
                        )
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient.brandGlow
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: Radius.md
                            )
                        )
                        .glow(color: .brandPurple)
                    }
                    .padding(.horizontal, Space.pagePadding)
                    .padding(
                        .bottom,
                        geo.safeAreaInsets.bottom + Space.md
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .appSpring.delay(0.3),
                        value: appeared
                    )
                    // MARK: - Skip Vote

                    Button {
                        Haptic.medium()
                        viewModel.skipVoting()
                    } label: {
                        Text("SKIP VOTE")
                            .font(AppFont.button(size: 15))
                            .tracking(
                                viewModel.selectedLanguage.isRTL
                                ? 0
                                : 3
                            )
                            .foregroundStyle(
                                Color.white.opacity(0.55)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color.white.opacity(0.04)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: Radius.md
                                )
                            )
                            .overlay(
                                RoundedRectangle(
                                    cornerRadius: Radius.md
                                )
                                .strokeBorder(
                                    Color.appBorder,
                                    lineWidth: 1
                                )
                            )
                    }
                    .padding(.horizontal, Space.pagePadding)
                    .padding(.bottom, geo.safeAreaInsets.bottom + Space.md)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .appSpring.delay(0.35),
                        value: appeared
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.appDramatic) {
                appeared = true
            }
        }
        .environment(
            \.layoutDirection,
            viewModel.selectedLanguage.layoutDirection
        )
    }

    // MARK: - Player chips

    private var playerChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLAYERS")
                .font(AppFont.label(size: 10))
                .foregroundStyle(
                    Color.white.opacity(0.3)
                )
                .tracking(2)

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 8) {
                    ForEach(
                        Array(
                            viewModel.players.enumerated()
                        ),
                        id: \.element.id
                    ) { idx, player in

                        VStack(spacing: 4) {
                            PlayerChip(
                                player: player,
                                index: idx,
                                isAlive: !player.isEliminated
                            )

                            Text(
                                String(
                                    player.name.prefix(5)
                                )
                            )
                            .font(
                                AppFont.body(
                                    size: 9,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(
                                player.isEliminated
                                ? Color.white.opacity(0.2)
                                : Color.white.opacity(0.55)
                            )
                            .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(Space.md)
        .glassCard()
    }

    // MARK: - Hint card

    private var hintCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 20))
                .foregroundStyle(Color.brandPurple)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    viewModel.selectedLanguage.strings.findUndercover
                )
                .font(
                    AppFont.body(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)

                Text(
                    viewModel.selectedLanguage.strings.discussClues
                )
                .font(AppFont.body(size: 12))
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )
            }

            Spacer()
        }
        .padding(Space.md)
        .glassCard()
    }
}
