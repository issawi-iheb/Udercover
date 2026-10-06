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
    @FocusState private var nameFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var canStart: Bool { viewModel.players.count >= 3 }
    private var strings: AppStrings {
        viewModel.selectedLanguage.strings
    }

    public var body: some View {
        ZStack {
            LinearGradient.brandBackground.ignoresSafeArea()

            // Ambient glow
            Circle().fill(Color.brandPurple.opacity(0.18)).blur(radius: 140)
                .offset(x: -100, y: -280).allowsHitTesting(false)
                .accessibilityHidden(true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Space.lg) {
                    header
                    difficultySection
                    topicSection
                    languageSection
                    mrWhiteSection
                    playerSection
                    addPlayerField
                    startSection
                }
                .padding(.horizontal, Space.pagePadding)
                .padding(.top, Space.md)
                .padding(.bottom, 48)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                }
                .accessibilityLabel(strings.backButton)
                .accessibilityHint(strings.backButtonHint)
            }
        }
        .onAppear {
            viewModel.availableTopics = appState.topics
            withAnimation(.appDramatic) {
            appeared = true
        }
    }
        .fullScreenCover(isPresented: $showGame) { GameRootView(viewModel: viewModel) }
        .onChange(of: viewModel.gameState) { _, new in
            if new != .setup  { showGame = true }
        }
        .environment(\.layoutDirection, viewModel.selectedLanguage.layoutDirection)
    }
        

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text(strings.lobby)
                .font(AppFont.label()).foregroundStyle(Color.brandPurple).tracking(4)
            Text(strings.setUpYourGame)
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
            sectionLabel(strings.difficulty)

            HStack(spacing: 10) {
                ForEach(PairDifficulty.allCases, id: \.self) { diff in
                    DifficultyButton(
                        difficulty: diff,
                        isSelected: viewModel.selectedDifficulty == diff, strings: strings,
                        action: {
                            Haptic.light()
                            withAnimation(.appSnap) {
                                viewModel.selectDifficulty(diff)
                            }
                        }
                    )
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.appDramatic.delay(0.12), value: appeared)
        }
    }

    // MARK: - Topic pills

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel(strings.topic)
                Spacer()
                Text(viewModel.selectedTopic?.capitalized ?? strings.random)
                    .font(AppFont.label(size: 10))
                    .foregroundStyle(Color.brandPurple)
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TopicPill(label: strings.random, icon: "shuffle",
                              isSelected: viewModel.selectedTopic == nil, strings: strings) {
                        Haptic.light()
                        withAnimation(.appSnap) {
                            viewModel.selectTopic(nil)
                        }
                    }
                    ForEach(appState.topics) { topic in

                        TopicPill(
                            label: topic.name,
                            icon: topicIcon(topic.name),
                            isSelected: viewModel.selectedTopic == topic.id, strings: strings
                        ) {
                            Haptic.light()

                            withAnimation(.appSnap) {
                                viewModel.selectTopic(topic.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 4)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
        .animation(.appDramatic.delay(0.18), value: appeared)
    }

    // MARK: - Language + Mr. White
    @ViewBuilder
    private var mrWhiteSection: some View {
        if viewModel.players.count >= 4 {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPink.opacity(0.20),
                                    Color.brandPurple.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    Color.white.opacity(0.10),
                                    lineWidth: 1
                                )
                        }

                    Image(systemName: "suit.club.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color.brandPink)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(strings.mrWhite)
                            .font(AppFont.body(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("OPTIONAL")
                            .font(AppFont.label(size: 8))
                            .tracking(1)
                            .foregroundStyle(Color.brandPink.opacity(0.75))
                    }

                    Text(strings.mrWhiteDescription)
                        .font(AppFont.body(size: 11))
                        .foregroundStyle(Color.white.opacity(0.38))
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                Toggle("", isOn: $viewModel.mrWhiteModeEnabled)
                    .labelsHidden()
                    .tint(.brandPink)
                    .accessibilityLabel(strings.mrWhite)
                    .accessibilityHint(strings.mrWhiteToggleHint)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPink.opacity(0.055),
                                Color.white.opacity(0.035)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(
                        Color.brandPink.opacity(
                            viewModel.mrWhiteModeEnabled ? 0.25 : 0.08
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 12,
                y: 6
            )
            .animation(.easeOut(duration: 0.2), value: viewModel.mrWhiteModeEnabled)
            .transition(
                .move(edge: .top)
                    .combined(with: .opacity)
            )
        }
    }
    
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel(strings.languageSection)

                Spacer()

                Text(viewModel.selectedLanguage.displayName)
                    .font(AppFont.label(size: 10))
                    .foregroundStyle(Color.brandPurple)
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        LanguagePill(
                            language: language,
                            isSelected: viewModel.selectedLanguage == language,
                            strings: strings
                        ) {
                            Haptic.light()

                            withAnimation(.appSnap) {
                                viewModel.selectLanguage(language)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.appDramatic.delay(0.22), value: appeared)
    }
    // MARK: - Player card stack
    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel(strings.players)
                Spacer()
                Text("\(viewModel.players.count) / 10")
                    .font(AppFont.label(size: 11))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .accessibilityLabel(strings.playerCount(viewModel.players.count))
            }

            if !viewModel.players.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(
                            Array(viewModel.players.enumerated()),
                            id: \.element.id
                        ) { index, player in
                            lobbyPlayerBadge(
                                player: player,
                                index: index
                            )
                            
                            
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(
            .appDramatic.delay(0.26),
            value: appeared
        )
    }
    
    private func lobbyPlayerBadge(
        player: Player,
        index: Int
    ) -> some View {
        let accent = Color.avatar(for: index)

        return VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(accent.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                accent.opacity(0.4),
                                lineWidth: 1
                            )
                    }
                    .overlay {
                        Text(
                            String(
                                player.name
                                    .prefix(1)
                                    .uppercased()
                            )
                        )
                        .font(AppFont.playerName(size: 17))
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                    }

                Button {
                    withAnimation(.appSnap) {
                        viewModel.removePlayer(
                            at: IndexSet(integer: index)
                        )
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.red)
                        .accessibilityHidden(true)
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
                .accessibilityLabel(strings.removePlayerLabel(player.name))
                .accessibilityHint(strings.removePlayerHint)
            }

            Text(player.name)
                .font(AppFont.body(size: 9, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 60)
        }
    }
    

    // MARK: - Add player field
    
    private var addPlayerField: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.brandPurple)
                .frame(width: 22)
                .accessibilityHidden(true)

            TextField(strings.playerNamePlaceholder, text: $playerName)
                .accessibilityLabel(strings.playerNamePlaceholder)
                .focused($nameFocused)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .onSubmit { addPlayer() }

            Button(action: addPlayer) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(
                                playerName.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? AnyShapeStyle(Color.white.opacity(0.07))
                                    : AnyShapeStyle(LinearGradient.brandGlow)
                            )
                    }
            }
            .buttonStyle(.plain)
            .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel(strings.addPlayerButtonLabel)
            .accessibilityHint(strings.addPlayerHint)
            .opacity(
                playerName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1
            )
            .animation(.easeOut(duration: 0.2), value: playerName)
        }
        .padding(.leading, 14)
        .padding(.trailing, 7)
        .frame(height: 54)
        .background {
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.white.opacity(0.055))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(
                    Color.white.opacity(0.10),
                    lineWidth: 1
                )
        }
        .opacity(appeared ? 1 : 0)
        .animation(.appDramatic.delay(0.30), value: appeared)
    }

    // MARK: - Start button

    private var startSection: some View {
        VStack(spacing: 12) {
            Button {
                Haptic.heavy()
                Task { await viewModel.startGame() }
            } label: {
                HStack(spacing: 14) {
                    Text(strings.startGame)
                        .font(AppFont.button(size: 18)).tracking(2)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .accessibilityHidden(true)
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
                .glow(color: canStart ? .brandPurple : .clear, radius: 10)
            }
            .disabled(!canStart || viewModel.isGeneratingWords)
            .accessibilityLabel(strings.startGame)
            .accessibilityHint(strings.startGameHint)
            .animation(.appSnap, value: canStart)

            if !canStart {
                Text(strings.needMorePlayers(
                    max(0, 3 - viewModel.players.count)
                ))
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
        nameFocused = false
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
    let strings: AppStrings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(difficulty.emoji)
                    .font(.system(size: 22))
                    .accessibilityHidden(true)

                Text(strings.difficultyLabel(difficulty))
                    .font(AppFont.label(size: 11))
                    .tracking(1)
                    .foregroundStyle(
                        isSelected
                            ? difficulty.color
                            : Color.white.opacity(0.4)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? difficulty.color.opacity(0.15)
                    : Color.white.opacity(0.04)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: Radius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(
                        isSelected
                            ? difficulty.color.opacity(0.6)
                            : Color.appBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.appSnap, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(strings.difficultyLabel(difficulty))
        .accessibilityValue(isSelected ? strings.selected : strings.notSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(strings.selectDifficultyHint)
    }
}

// MARK: ─── TopicPill ─────────────────────────────────────────────────────────

private struct TopicPill: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let strings: AppStrings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                    .font(.system(size: 11, weight: .semibold))

                Text(label)
                    .font(AppFont.body(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.5))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? LinearGradient.brandGlow
                    : LinearGradient(
                        colors: [Color.white.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.clear : Color.appBorder,
                    lineWidth: 1
                )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.appSnap, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(strings.selectTopicHint)
    }
}
// MARK: ─── LanguagePill ─────────────────────────────────────────────────────────

private struct LanguagePill: View {
    let language: AppLanguage
    let isSelected: Bool
    let strings: AppStrings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(flag)
                    .font(.system(size: 16))
                    .accessibilityHidden(true)

                Text(language.displayName)
                    .font(AppFont.label(size: 10))
                    .tracking(0.5)
                    .foregroundStyle(
                        isSelected
                            ? Color.white
                            : Color.white.opacity(0.45)
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected
                    ? Color.brandPurple.opacity(0.22)
                    : Color.white.opacity(0.05)
            )
            .overlay {
                Capsule()
                    .stroke(
                        isSelected
                            ? Color.brandPurple.opacity(0.7)
                            : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language.displayName)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(strings.selectLanguageHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var flag: String {
        switch language {
        case .english:
            return "🇬🇧"
        case .french:
            return "🇫🇷"
        case .arabic:
            return "🇸🇦"
        case .spanish:
            return "🇪🇸"
        case .tunisian:
            return "🇹🇳"
        }
    }

    private var accessibilityValue: String {
        if isSelected {
            return strings.selected
        } else {
            return strings.notSelected
        }
    }
}
