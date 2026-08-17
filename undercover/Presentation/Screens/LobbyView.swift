//
//  LobbyView.swift
//  undercoverApp
//

import SwiftUI

public struct LobbyView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = GameViewModel()
    @State private var playerName  = ""
    @State private var appeared    = false
    @State private var showGame    = false
    @State private var nameFocused = false
    @Environment(\.dismiss) private var dismiss

    private var canStart: Bool { viewModel.players.count >= 3 }

    public var body: some View {
        ZStack {
            LinearGradient.brandBackground.ignoresSafeArea()

            // Ambient glow
            Circle().fill(Color.brandPurple.opacity(0.18)).blur(radius: 140)
                .offset(x: -100, y: -280).allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Space.xl) {
                    header
                    difficultySection
                    topicSection
                    mrWhiteToggle
                    playerSection
                    addPlayerField
                    startSection
                }
                .padding(.horizontal, Space.pagePadding)
                .padding(.top, Space.md)
                .padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                }
            }
        }
        .onAppear { withAnimation(.appDramatic) {
            appeared = true
            viewModel.availableTopics = appState.topics
        }
    }
        .fullScreenCover(isPresented: $showGame) { GameRootView(viewModel: viewModel) }
        .onChange(of: viewModel.gameState) { _, new in
            if new != .setup && new != .loadingWords { showGame = true }
        }
        .environment(\.layoutDirection, viewModel.selectedLanguage.layoutDirection)
    }
        

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("LOBBY")
                .font(AppFont.label()).foregroundStyle(Color.brandPurple).tracking(4)
            Text("Set up your game")
                .font(.system(size: 28, weight: .black, design: .rounded)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, Space.md)
        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
        .animation(.appDramatic.delay(0.05), value: appeared)
    }

    // MARK: - Difficulty (tactile buttons, not picker)

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("DIFFICULTY")

            HStack(spacing: 10) {
                ForEach(PairDifficulty.allCases, id: \.self) { diff in
                    DifficultyButton(
                        difficulty: diff,
                        isSelected: viewModel.selectedDifficulty == diff
                    ) {
                        Haptic.light()
                        withAnimation(.appSnap) { viewModel.selectedDifficulty = diff }
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
        .animation(.appDramatic.delay(0.12), value: appeared)
    }

    // MARK: - Topic pills

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("TOPIC")
                Spacer()
                Text(viewModel.selectedTopic?.capitalized ?? "Random")
                    .font(AppFont.label(size: 10))
                    .foregroundStyle(Color.brandPurple)
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TopicPill(label: "Random", icon: "shuffle",
                              isSelected: viewModel.selectedTopic == nil) {
                        Haptic.light()
                        withAnimation(.appSnap) { viewModel.selectedTopic = nil }
                    }
                    ForEach(appState.topics) { topic in

                        TopicPill(
                            label: topic.name,
                            icon: topicIcon(topic.name),
                            isSelected: viewModel.selectedTopic == topic.id
                        ) {
                            Haptic.light()

                            withAnimation(.appSnap) {
                                viewModel.selectedTopic = topic.id
                            }
                        }
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 4)
            }
        }
        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
        .animation(.appDramatic.delay(0.18), value: appeared)
    }

    // MARK: - Language + Mr. White

    private var mrWhiteToggle: some View {
        VStack(spacing: 10) {
            // Language row
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 14)).foregroundStyle(Color.brandPurple).frame(width: 28)
                Text("Language")
                    .font(AppFont.body(size: 15, weight: .medium)).foregroundStyle(.white)
                Spacer()
                Picker("", selection: $viewModel.selectedLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .pickerStyle(.menu).tint(.brandPurple)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .glassCard()

            // Mr. White toggle (only if 4+ players)
            if viewModel.players.count >= 4 {
                HStack {
                    ZStack {
                        Circle().fill(Color.brandPink.opacity(0.15)).frame(width: 32, height: 32)
                        Text("🃏").font(.system(size: 16))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mr. White")
                            .font(AppFont.body(size: 15, weight: .semibold)).foregroundStyle(.white)
                        Text("One player gets no word and must bluff")
                            .font(AppFont.body(size: 11)).foregroundStyle(Color.white.opacity(0.4))
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.mrWhiteModeEnabled).tint(.brandPink)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .glassCard()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
        .animation(.appDramatic.delay(0.22), value: appeared)
    }

    // MARK: - Player card stack

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("PLAYERS")
                Spacer()
                Text("\(viewModel.players.count) / 10")
                    .font(AppFont.label(size: 11)).foregroundStyle(Color.white.opacity(0.35))
            }

            if viewModel.players.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 28)).foregroundStyle(Color.brandPurple.opacity(0.4))
                    Text("Add at least 3 players to start")
                        .font(AppFont.body(size: 14)).foregroundStyle(Color.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 32)
                .glassCard()
            } else {
                VStack(spacing: 1) {
                    ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { idx, player in
                        PlayerCard(player: player, index: idx) {
                            withAnimation(.appSnap) {
                                viewModel.removePlayer(at: IndexSet(integer: idx))
                            }
                        }
                        if idx < viewModel.players.count - 1 {
                            Divider().background(Color.appBorder).padding(.leading, 60)
                        }
                    }
                }
                .glassCard()
            }
        }
        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
        .animation(.appDramatic.delay(0.26), value: appeared)
    }

    // MARK: - Add player field

    private var addPlayerField: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16)).foregroundStyle(Color.brandPurple)
                    .padding(.leading, 4)

                TextField("Player name…", text: $playerName)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onSubmit { addPlayer() }
            }
            .padding(.vertical, 14).padding(.horizontal, 12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.appBorder, lineWidth: 1))

            Button(action: addPlayer) {
                ZStack {
                    Circle()
                        .foregroundStyle(
                            playerName.trimmingCharacters(in: .whitespaces).isEmpty
                                ? LinearGradient(colors: [.white.opacity(0.06), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient.brandGlow
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .opacity(appeared ? 1 : 0).animation(.appDramatic.delay(0.30), value: appeared)
    }

    // MARK: - Start button

    private var startSection: some View {
        VStack(spacing: 12) {
            Button {
                Haptic.heavy()
                Task { await viewModel.startGame() }
            } label: {
                ZStack {
                    if viewModel.isGeneratingWords {
                        HStack(spacing: 12) {
                            ProgressView().tint(.white)
                            Text("Finding words…").font(AppFont.button())
                        }
                    } else {
                        HStack(spacing: 14) {
                            Text("START GAME")
                                .font(AppFont.button(size: 18)).tracking(2)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 20)
                .background(
                    canStart
                        ? LinearGradient.brandGlow
                        : LinearGradient(colors: [.white.opacity(0.07), .white.opacity(0.05)],
                                         startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .glow(color: canStart ? .brandPurple : .clear, radius: 18)
            }
            .disabled(!canStart || viewModel.isGeneratingWords)
            .animation(.appSnap, value: canStart)

            if !canStart {
                Text("Need \(max(0, 3 - viewModel.players.count)) more player\(3 - viewModel.players.count == 1 ? "" : "s")")
                    .font(AppFont.label(size: 11))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .tracking(1)
            }
        }
        .opacity(appeared ? 1 : 0).animation(.appDramatic.delay(0.34), value: appeared)
    }

    // MARK: - Helpers

    private func addPlayer() {
        let trimmed = playerName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, viewModel.players.count < 10 else { return }
        Haptic.playerAdded()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            viewModel.addPlayer(name: trimmed)
        }
        playerName = ""
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.label()).foregroundStyle(Color.white.opacity(0.35)).tracking(2)
    }

    private func topicIcon(_ topic: String) -> String {
        let map: [String: String] = [
            "animals":"pawprint.fill","food":"fork.knife","fruits":"leaf.fill",
            "sports":"sportscourt.fill","technology":"cpu","music":"music.note",
            "movies":"film.fill","transport":"car.fill","jobs":"briefcase.fill",
            "cities":"building.2.fill","drinks":"cup.and.saucer.fill",
            "nature":"mountain.2.fill","clothing":"tshirt.fill",
            "household":"house.fill","weather":"cloud.sun.fill",
        ]
        return map[topic] ?? "square.grid.2x2.fill"
    }
}

// MARK: ─── DifficultyButton ───────────────────────────────────────────────────

private struct DifficultyButton: View {
    let difficulty: PairDifficulty
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(difficulty.emoji).font(.system(size: 22))
                Text(difficulty.label)
                    .font(AppFont.label(size: 11)).tracking(1)
                    .foregroundStyle(isSelected ? difficulty.color : Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(
                isSelected
                    ? difficulty.color.opacity(0.15)
                    : Color.white.opacity(0.04)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(
                    isSelected ? difficulty.color.opacity(0.6) : Color.appBorder,
                    lineWidth: isSelected ? 1.5 : 1
                )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.appSnap, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: ─── TopicPill ─────────────────────────────────────────────────────────

private struct TopicPill: View {
    let label:      String
    let icon:       String
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(label).font(AppFont.body(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.5))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isSelected ? LinearGradient.brandGlow : LinearGradient(
                colors: [Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing
            ))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(
                isSelected ? Color.clear : Color.appBorder, lineWidth: 1
            ))
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.appSnap, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: ─── PlayerCard ─────────────────────────────────────────────────────────

private struct PlayerCard: View {
    let player: Player
    let index:  Int
    let onRemove: () -> Void

    private var accent: Color { .avatar(for: index) }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle().fill(accent.opacity(0.2)).frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(accent.opacity(0.4), lineWidth: 1))
                Text(String(player.name.prefix(1)).uppercased())
                    .font(AppFont.playerName(size: 17)).foregroundStyle(accent)
            }

            Text(player.name)
                .font(AppFont.body(size: 16, weight: .semibold)).foregroundStyle(.white)

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.md).padding(.vertical, 12)
        .background(Color.white.opacity(0.02))
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        ))
    }
}
