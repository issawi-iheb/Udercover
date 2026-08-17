//
//  VotingView.swift
//  undercoverApp
//

import SwiftUI

public struct VotingView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var appeared    = false
    @State private var confirming  = false   // show confirm overlay
    @State private var flashTrigger = false

    private var s: AppStrings { viewModel.selectedLanguage.strings }
    private var hasSelection: Bool { viewModel.selectedVotePlayerID != nil }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                // Hot red glow — sets the mood
                RadialGradient(
                    colors: [Color.dangerRed.opacity(0.22), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: geo.size.height * 0.7
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Screen flash on elimination
                ScreenFlash(color: .brandPink, trigger: $flashTrigger)

                VStack(spacing: 0) {
                    Spacer(minLength: 32)

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.brandPink.opacity(0.14))
                                .frame(width: 72, height: 72)
                            if hasSelection {
                                PulsingRing(color: .brandPink,
                                            size: 80)
                            }
                            Image(systemName: "person.fill.xmark")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.brandPink)
                        }

                        Text(s.voteOut)
                            .font(AppFont.label())
                            .foregroundStyle(Color.brandPink)
                            .tracking(viewModel.selectedLanguage.isRTL ? 0 : 4)

                        Text(s.whoIsUndercover)
                            .font(.system(size: 25,
                                          weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Space.lg)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -16)
                    .animation(.appDramatic.delay(0.05), value: appeared)

                    Spacer(minLength: Space.md)

                    // Player grid — all players (eliminated shown as ghosts)
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12),
                                      GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { idx, player in
                                VoteCard(
                                    player:      player,
                                    index:       idx,
                                    isSelected:  viewModel.selectedVotePlayerID == player.id,
                                    isEliminated: player.isEliminated,
                                    dimmed:      hasSelection && viewModel.selectedVotePlayerID != player.id && !player.isEliminated
                                ) {
                                    guard !player.isEliminated else { return }
                                    Haptic.voteCast()
                                    withAnimation(.appSnap) {
                                        viewModel.selectedVotePlayerID = player.id
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Space.md)
                        .padding(.top, 6)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.appDramatic.delay(0.12), value: appeared)

                    Spacer(minLength: Space.md)

                    // Confirm button
                    Button {
                        guard hasSelection else { return }
                        Haptic.heavy()
                        withAnimation(.appSnap) { confirming = true }
                    } label: {
                        HStack(spacing: 12) {
                           // Image(systemName: "gavel")
                                //.font(.system(size: 18, weight: .bold))
                            Text(s.confirmVote)
                                .font(AppFont.button())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(hasSelection
                            ? LinearGradient.dangerGlow
                            : LinearGradient(colors: [.white.opacity(0.07), .white.opacity(0.05)],
                                             startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .glow(color: hasSelection ? .brandPink : .clear)
                    }
                    .disabled(!hasSelection)
                    .padding(.horizontal, Space.pagePadding)
                    .padding(.bottom, geo.safeAreaInsets.bottom + Space.md)
                    .animation(.appSnap, value: hasSelection)
                    .opacity(appeared ? 1 : 0)
                    .animation(.appDramatic.delay(0.18), value: appeared)
                }

                // Confirmation overlay
                if confirming, let votedID = viewModel.selectedVotePlayerID,
                   let votedPlayer = viewModel.players.first(where: { $0.id == votedID }) {
                    confirmationOverlay(player: votedPlayer, geo: geo)
                        .transition(.opacity)
                }
            }
        }
        .onAppear { withAnimation(.appDramatic) { appeared = true } }
        .environment(\.layoutDirection, viewModel.selectedLanguage.layoutDirection)
    }

    // MARK: - Confirmation overlay

    private func confirmationOverlay(player: Player, geo: GeometryProxy) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
                .onTapGesture { withAnimation(.appSnap) { confirming = false } }

            VStack(spacing: Space.lg) {
                Text("ELIMINATE")
                    .font(AppFont.label(size: 14))
                    .foregroundStyle(Color.brandPink)
                    .tracking(4)

                Text(player.name)
                    .font(AppFont.playerName(size: 36))
                    .foregroundStyle(.white)

                Text("Are you sure? This cannot be undone.")
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .multilineTextAlignment(.center)

                HStack(spacing: 14) {
                    // Cancel
                    Button {
                        withAnimation(.appSnap) { confirming = false }
                    } label: {
                        Text("CANCEL")
                            .font(AppFont.button(size: 15)).tracking(1)
                            .foregroundStyle(Color.white.opacity(0.6))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .overlay(RoundedRectangle(cornerRadius: Radius.md)
                                .strokeBorder(Color.appBorder, lineWidth: 1))
                    }

                    // Confirm
                    Button {
                        confirming = false
                        flashTrigger = true
                        Haptic.playerEliminated()
                        withAnimation(.appSnap) { viewModel.finishVoting() }
                    } label: {
                        Text("ELIMINATE")
                            .font(AppFont.button(size: 15)).tracking(1)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient.dangerGlowStrong)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .glow(color: .dangerRed, radius: 12)
                    }
                }
            }
            .padding(Space.xl)
            .glassCard(cornerRadius: Radius.xl)
            .padding(.horizontal, Space.lg)
            .scaleEffect(confirming ? 1 : 0.9)
            .animation(.appDramatic, value: confirming)
        }
    }
}

// MARK: ─── VoteCard ───────────────────────────────────────────────────────────

public struct VoteCard: View {
    let player:       Player
    let index:        Int
    let isSelected:   Bool
    let isEliminated: Bool
    let dimmed:       Bool
    let onTap:        () -> Void

    private var accent: Color { .avatar(for: index) }

    public var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 10) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(isEliminated
                                  ? Color.white.opacity(0.04)
                                  : accent.opacity(isSelected ? 0.28 : 0.12))
                            .frame(width: 64, height: 64)
                            .overlay(Circle().strokeBorder(
                                isSelected ? accent : (isEliminated ? Color.white.opacity(0.08) : Color.clear),
                                lineWidth: isSelected ? 2 : 1
                            ))

                        Text(String(player.name.prefix(1)).uppercased())
                            .font(AppFont.playerName(size: 22))
                            .foregroundStyle(isEliminated ? Color.white.opacity(0.15) : accent)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(accent)
                                .offset(x: 22, y: -22)
                        }

                        if isEliminated {
                            // Ghost X overlay
                            ZStack {
                                Circle().fill(Color.black.opacity(0.4)).frame(width: 64, height: 64)
                                Image(systemName: "xmark")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundStyle(Color.brandPink.opacity(0.7))
                            }
                        }
                    }

                    Text(player.name)
                        .font(AppFont.body(size: 14, weight: .semibold))
                        .foregroundStyle(isEliminated
                            ? Color.white.opacity(0.2)
                            : (isSelected ? .white : Color.white.opacity(0.7)))
                        .lineLimit(1)

                    if isEliminated {
                        Text("ELIMINATED")
                            .font(AppFont.label(size: 9))
                            .foregroundStyle(Color.brandPink.opacity(0.5))
                            .tracking(1)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: Radius.md)
                    .fill(isSelected
                          ? accent.opacity(0.14)
                          : (isEliminated ? Color.white.opacity(0.02) : Color.white.opacity(0.04))))
                .overlay(RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(
                        isSelected ? accent.opacity(0.6)
                            : (isEliminated ? Color.white.opacity(0.06) : Color.appBorder),
                        lineWidth: isSelected ? 1.5 : 1
                    ))
                .scaleEffect(isSelected ? 1.04 : 1.0)
            }
            // Dimming when another card is selected
            .opacity(isEliminated ? 0.6 : (dimmed ? 0.45 : 1.0))
            .animation(.appSnap, value: isSelected)
            .animation(.appSnap, value: dimmed)
        }
        .buttonStyle(.plain)
        .disabled(isEliminated)
    }
}
