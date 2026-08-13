//
//  VotingView.swift
//  undercoverApp
//

import SwiftUI

public struct VotingView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var appeared = false
    private var s: AppStrings { viewModel.selectedLanguage.strings }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(Color.brandPink.opacity(0.10)).frame(width: 420).blur(radius: 100)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                VStack(spacing: 0) {
                    Spacer(minLength: adaptiveTop)

                    // Header
                    VStack(spacing: adaptiveHeaderSpacing) {
                        ZStack {
                            Circle().fill(Color.brandPink.opacity(0.12))
                                .frame(width: adaptiveIconSize, height: adaptiveIconSize)
                            Image(systemName: "person.fill.xmark")
                                .font(.system(size: adaptiveIconFont))
                                .foregroundStyle(Color.brandPink)
                        }
                        Text(s.voteOut)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.brandPink)
                            .tracking(viewModel.selectedLanguage.isRTL ? 0 : 4)
                        Text(s.whoIsUndercover)
                            .font(.system(size: adaptiveTitle, weight: .black, design: .rounded))
                            .foregroundStyle(.white).multilineTextAlignment(.center).padding(.horizontal, 28)
                    }
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : -10)

                    Spacer(minLength: 12)

                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(Array(viewModel.alivePlayers.enumerated()), id: \.element.id) { idx, player in
                                VoteCard(
                                    player: player, index: idx,
                                    isSelected: viewModel.selectedVotePlayerID == player.id
                                ) {
                                    Haptic.medium()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        viewModel.selectedVotePlayerID = player.id
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 6)
                    }

                    Spacer(minLength: 12)

                    Button {
                        Haptic.heavy()
                        withAnimation { viewModel.finishVoting() }
                    } label: {
                        Label(s.confirmVote, systemImage: "gavel")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(
                                viewModel.selectedVotePlayerID != nil
                                    ? LinearGradient.dangerGlow
                                    : LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.06)],
                                                     startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .glow(color: viewModel.selectedVotePlayerID != nil ? .brandPink : .clear)
                    }
                    .disabled(viewModel.selectedVotePlayerID == nil)
                    .padding(.horizontal, 24).padding(.bottom, geo.safeAreaInsets.bottom + 16)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedVotePlayerID != nil)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear { withAnimation(.spring().delay(0.1)) { appeared = true } }
        .environment(\.layoutDirection, viewModel.selectedLanguage.layoutDirection)
    }

    private var adaptiveTop:           CGFloat { UIScreen.main.bounds.height < 700 ? 20 : 40 }
    private var adaptiveHeaderSpacing: CGFloat { UIScreen.main.bounds.height < 700 ? 8  : 12 }
    private var adaptiveIconSize:      CGFloat { UIScreen.main.bounds.height < 700 ? 64 : 80 }
    private var adaptiveIconFont:      CGFloat { UIScreen.main.bounds.height < 700 ? 24 : 30 }
    private var adaptiveTitle:         CGFloat { UIScreen.main.bounds.height < 700 ? 20 : 24 }
}

// MARK: - VoteCard

public struct VoteCard: View {
    let player: Player
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    private var accent: Color { .avatar(for: index) }

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(accent.opacity(isSelected ? 0.25 : 0.12)).frame(width: 64, height: 64)
                        .overlay(Circle().strokeBorder(isSelected ? accent : Color.clear, lineWidth: 1.5))
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(accent)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 18))
                            .foregroundStyle(accent).offset(x: 22, y: -22)
                    }
                }
                Text(player.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.75)).lineLimit(1)
            }
            .padding(12).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? accent.opacity(0.12) : Color.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isSelected ? accent.opacity(0.6) : Color.appBorder,
                              lineWidth: isSelected ? 1.2 : 1))
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
        }.buttonStyle(.plain)
    }
}
