//
//  LobbyView.swift
//  undercoverApp
//

import SwiftUI

public struct LobbyView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var playerName = ""
    @State private var appeared   = false
    @State private var showGame   = false
    @Environment(\.dismiss) private var dismiss

    private var canStart: Bool { viewModel.players.count >= 3 }

    public var body: some View {
        ZStack {
            LinearGradient.brandBackground.ignoresSafeArea()
            Circle().fill(Color.brandPurple.opacity(0.18)).blur(radius: 130).offset(x: -100, y: -260)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    settingsCard
                    playersCard
                    addPlayerRow
                    startButton.padding(.bottom, 40)
                }
                .padding(.horizontal, 22)
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
        .onAppear { appeared = true }
        .fullScreenCover(isPresented: $showGame) { GameRootView(viewModel: viewModel) }
        .onChange(of: viewModel.gameState) { _, new in
            if new != .setup && new != .loadingWords { showGame = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("LOBBY")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.brandPurple).tracking(4)
            Text("Set up your game")
                .font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(.white)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .animation(.spring().delay(0.1), value: appeared)
    }

    // MARK: - Settings card

    private var settingsCard: some View {
        VStack(spacing: 0) {
            sectionLabel("SETTINGS")
            VStack(spacing: 0) {
                pickerRow(icon: "globe", label: "Language",
                          binding: $viewModel.selectedLanguage,
                          options: AppLanguage.allCases, display: \.displayName)
                divider
                pickerRow(icon: "flame", label: "Difficulty",
                          binding: $viewModel.selectedDifficulty,
                          options: PairDifficulty.allCases, display: \.label)
                divider
                topicRow

                if viewModel.players.count >= 4 {
                    divider
                    toggleRow(icon: "person.fill.questionmark",
                              label: "Mr. White Mode",
                              binding: $viewModel.mrWhiteModeEnabled)
                }
            }
            .glassCard(cornerRadius: 16)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring().delay(0.2), value: appeared)
    }

    private var topicRow: some View {
        HStack {
            Image(systemName: "tag").font(.system(size: 14)).foregroundStyle(Color.brandPurple).frame(width: 28)
            Text("Topic").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white)
            Spacer()
            Picker("", selection: Binding(
                get:  { viewModel.selectedTopic ?? "" },
                set:  { viewModel.selectedTopic = $0.isEmpty ? nil : $0 }
            )) {
                Text("Random").tag("")
                ForEach(viewModel.availableTopics, id: \.self) { Text($0.capitalized).tag($0) }
            }
            .pickerStyle(.menu).tint(.brandPurple)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Players card

    private var playersCard: some View {
        VStack(spacing: 0) {
            HStack {
                sectionLabel("PLAYERS")
                Spacer()
                Text("\(viewModel.players.count) / 10")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
            }

            if viewModel.players.isEmpty {
                Text("Add at least 3 players to start")
                    .font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.3))
                    .frame(maxWidth: .infinity).padding(.vertical, 28)
                    .glassCard(cornerRadius: 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { idx, player in
                        playerRow(player: player, index: idx)
                        if idx < viewModel.players.count - 1 { divider.padding(.leading, 66) }
                    }
                }
                .glassCard(cornerRadius: 16)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring().delay(0.3), value: appeared)
    }

    private func playerRow(player: Player, index: Int) -> some View {
        HStack(spacing: 14) {
            Circle().fill(Color.avatar(for: index).opacity(0.2)).frame(width: 36, height: 36)
                .overlay(
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Color.avatar(for: index))
                )
            Text(player.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .swipeActions {
            Button(role: .destructive) {
                viewModel.removePlayer(at: IndexSet(integer: index))
            } label: { Label("Remove", systemImage: "trash") }
        }
    }

    // MARK: - Add player

    private var addPlayerRow: some View {
        HStack(spacing: 12) {
            TextField("Player name", text: $playerName)
                .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                .autocorrectionDisabled().textInputAutocapitalization(.words)
                .padding(.vertical, 14).padding(.horizontal, 16)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.appBorder, lineWidth: 1))
                .onSubmit { addPlayer() }

            Button(action: addPlayer) {
                Image(systemName: "plus.circle.fill").font(.system(size: 36))
                    .foregroundStyle(playerName.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color.white.opacity(0.2) : Color.brandPurple)
            }
            .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring().delay(0.35), value: appeared)
    }

    // MARK: - Start button

    private var startButton: some View {
        Button {
            Haptic.heavy()
            Task { await viewModel.startGame() }
        } label: {
            Group {
                if viewModel.isGeneratingWords {
                    HStack(spacing: 12) {
                        ProgressView().tint(.white)
                        Text("Generating words…").font(.system(size: 16, weight: .semibold))
                    }
                } else {
                    HStack(spacing: 12) {
                        Text("START GAME").font(.system(size: 18, weight: .bold, design: .rounded)).tracking(2)
                        Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(canStart
                ? LinearGradient.brandGlow
                : LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.06)], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .glow(color: canStart ? .brandPurple : .clear, radius: 14)
        }
        .disabled(!canStart || viewModel.isGeneratingWords)
        .animation(.easeInOut(duration: 0.2), value: canStart)
        .opacity(appeared ? 1 : 0)
        .animation(.spring().delay(0.4), value: appeared)
    }

    // MARK: - Helpers

    private func addPlayer() {
        guard !playerName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        viewModel.addPlayer(name: playerName)
        playerName = ""
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.35)).tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 10)
    }

    private func pickerRow<T: Hashable>(icon: String, label: String, binding: Binding<T>, options: [T], display: KeyPath<T, String>) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Color.brandPurple).frame(width: 28)
            Text(label).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white)
            Spacer()
            Picker("", selection: binding) {
                ForEach(options, id: \.self) { Text($0[keyPath: display]).tag($0) }
            }
            .pickerStyle(.menu).tint(.brandPurple)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func toggleRow(icon: String, label: String, binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Color.brandPink).frame(width: 28)
            Text(label).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: binding).tint(.brandPink)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var divider: some View {
        Divider().background(Color.appBorder)
    }
}
