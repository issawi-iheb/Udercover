//
//  MrWhiteGuessView.swift
//  undercoverApp
//

import SwiftUI

public struct MrWhiteGuessView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var countdown    = 3
    @State private var showInput    = false
    @State private var appeared     = false
    @State private var submitted    = false
    @State private var flashTrigger = false
    @FocusState private var focused: Bool

    private var canSubmit: Bool {
        !viewModel.mrWhiteGuessInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Inverted palette — near-white background for Mr. White
                Color(hex: "#0E0E18").ignoresSafeArea()

                // White radial spotlight from center
                RadialGradient(
                    colors: [Color.white.opacity(0.06), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.height * 0.6
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Screen flash on submit
                ScreenFlash(color: .brandPink, trigger: $flashTrigger)

                if !showInput {
                    countdownView
                } else {
                    guessView(geo: geo)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .onAppear { startCountdown() }
    }

    // MARK: - Countdown 3…2…1…

    private var countdownView: some View {
        VStack(spacing: Space.xl) {
            Spacer()

            Text("MR. WHITE")
                .font(AppFont.label(size: 14))
                .foregroundStyle(Color.brandPink)
                .tracking(5)

            Text(viewModel.isFinalMrWhiteDuel ? "Final Guess" : "One Last Chance")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Guess the civilians' word to win.")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            ZStack {
                PulsingRing(color: .brandPink, size: 150)

                Circle()
                    .fill(Color.brandPink.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.brandPink.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )

                Text("\(countdown)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(Color.brandPink)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.appSnap, value: countdown)
            }

            Spacer()
        }
    }

    // MARK: - Guess input

    private func guessView(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: geo.size.height * 0.12)

            // Header
            VStack(spacing: Space.md) {
                ZStack {
                    Circle()
                        .fill(Color.brandPink.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Circle()
                        .strokeBorder(Color.brandPink.opacity(0.25), lineWidth: 1)
                        .frame(width: 118, height: 118)
                    Text("🃏").font(.system(size: 52))
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .animation(.appDramatic.delay(0.1), value: appeared)

                VStack(spacing: 8) {
                    Text("MR. WHITE")
                        .font(AppFont.label(size: 13))
                        .foregroundStyle(Color.brandPink)
                        .tracking(5)

                    Text("What is the civilians' word?")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("One correct guess wins it all.")
                        .font(AppFont.body(size: 14))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.appDramatic.delay(0.18), value: appeared)
            }

            Spacer(minLength: Space.xl)

            // Input card — styled like a white card
            VStack(spacing: Space.md) {
                // The "white card" input
                VStack(spacing: 10) {
                    Text("YOUR GUESS")
                        .font(AppFont.label(size: 10))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .tracking(3)

                    TextField("Type here…", text: $viewModel.mrWhiteGuessInput)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focused)
                        .padding(.vertical, Space.md)
                        .onChange(of: viewModel.mrWhiteGuessInput) { _, val in
                            // Limit to one word
                            if val.contains(" ") {
                                viewModel.mrWhiteGuessInput = String(val.split(separator: " ").first ?? Substring(val))
                            }
                        }
                }
                .padding(Space.lg)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card)
                                .strokeBorder(
                                    canSubmit ? Color.brandPink.opacity(0.6) : Color.appBorder,
                                    lineWidth: canSubmit ? 1.5 : 1
                                )
                        )
                )

                // Submit
                Button {
                    guard canSubmit else { return }
                    focused = false
                    submitted = true
                    flashTrigger = true
                    Haptic.heavy()

                    // Brief pause for drama before resolving
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        let correct = viewModel.mrWhiteGuessInput
                            .trimmingCharacters(in: .whitespaces)
                            .lowercased() == viewModel.currentCivilianWord.lowercased()
                        if correct { Haptic.mrWhiteWins() } else { Haptic.mrWhiteWrongGuess() }
                        withAnimation(.appSpring) { viewModel.submitMrWhiteGuess() }
                    }
                } label: {
                    ZStack {
                        if submitted {
                            HStack(spacing: 10) {
                                ProgressView().tint(.white).scaleEffect(0.9)
                                Text("Checking…").font(AppFont.button())
                            }
                        } else {
                            Text("SUBMIT GUESS")
                                .font(AppFont.button()).tracking(2)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(canSubmit && !submitted
                        ? LinearGradient.dangerGlow
                        : LinearGradient(colors: [.white.opacity(0.07), .white.opacity(0.05)],
                                         startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    .glow(color: canSubmit && !submitted ? .brandPink : .clear)
                }
                .disabled(!canSubmit || submitted)
                .animation(.appSnap, value: canSubmit)
            }
            .padding(.horizontal, Space.pagePadding)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .animation(.appDramatic.delay(0.26), value: appeared)

            Spacer(minLength: Space.xl)
        }
    }

    // MARK: - Countdown logic

    private func startCountdown() {
        countdown = 3
        Haptic.timerTick()

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
                Haptic.timerTick()
            } else {
                timer.invalidate()
                Haptic.cardFlip()
                withAnimation(.appDramatic) {
                    showInput = true
                    appeared  = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    focused = true
                }
            }
        }
    }
}
