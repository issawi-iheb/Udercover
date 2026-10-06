//
//  MrWhiteGuessView.swift
//  undercoverApp
//

import SwiftUI

public struct MrWhiteGuessView: View {
    
    @ObservedObject var viewModel: GameViewModel
    
    @State private var countdown = 3
    @State private var showInput = false
    @State private var appeared = false
    @State private var submitted = false
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
        .onAppear {
            startCountdown()
        }
        .environment(
            \.layoutDirection,
             viewModel.selectedLanguage.layoutDirection
        )
    }
    
    // MARK: - Countdown
    
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
        .padding(.horizontal, Space.pagePadding)
    }
    
    // MARK: - Guess
    
    private func guessView(
        geo: GeometryProxy
    ) -> some View {
        VStack(spacing: 0) {
            Spacer(
                minLength: geo.size.height * 0.10
            )
            
            header
            
            Spacer(minLength: Space.xl)
            
            liveGuessSection
            
            typedGuessSection
            
            Spacer(minLength: Space.xl)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: Space.md) {
            ZStack {
                Circle()
                    .fill(
                        Color.brandPink.opacity(0.12)
                    )
                    .frame(
                        width: 100,
                        height: 100
                    )
                
                Circle()
                    .strokeBorder(
                        Color.brandPink.opacity(0.25),
                        lineWidth: 1
                    )
                    .frame(
                        width: 118,
                        height: 118
                    )
                
                Text("🃏")
                    .font(.system(size: 52))
            }
            .scaleEffect(
                appeared ? 1 : 0.5
            )
            .opacity(
                appeared ? 1 : 0
            )
            .animation(
                .appDramatic.delay(0.1),
                value: appeared
            )
            
            VStack(spacing: 8) {
                Text("MR. WHITE")
                    .font(AppFont.label(size: 13))
                    .foregroundStyle(Color.brandPink)
                    .tracking(5)
                
                Text("Did Mr. White guess it?")
                    .font(
                        .system(
                            size: 26,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Say the guess out loud, then confirm the result.")
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(
                        Color.white.opacity(0.4)
                    )
                    .multilineTextAlignment(.center)
            }
            .opacity(
                appeared ? 1 : 0
            )
            .offset(
                y: appeared ? 0 : 20
            )
            .animation(
                .appDramatic.delay(0.18),
                value: appeared
            )
        }
        .padding(.horizontal, Space.pagePadding)
    }
    
    // MARK: - Live / Spoken Guess
    
    private var liveGuessSection: some View {
        VStack(spacing: Space.md) {
            Text("SPOKEN GUESS")
                .font(AppFont.label(size: 10))
                .foregroundStyle(
                    Color.white.opacity(0.3)
                )
                .tracking(2)
            
            HStack(spacing: 10) {
                Button {
                    resolveLiveGuess(
                        correct: true
                    )
                } label: {
                    Label(
                        "GOT IT",
                        systemImage: "checkmark"
                    )
                    .font(
                        AppFont.button(size: 14)
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Color.green.opacity(0.16)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Radius.md
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: Radius.md
                        )
                        .strokeBorder(
                            Color.green.opacity(0.35),
                            lineWidth: 1
                        )
                    }
                }
                
                Button {
                    resolveLiveGuess(
                        correct: false
                    )
                } label: {
                    Label(
                        "WRONG",
                        systemImage: "xmark"
                    )
                    .font(
                        AppFont.button(size: 14)
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Color.accentRed.opacity(0.12)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Radius.md
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: Radius.md
                        )
                        .strokeBorder(
                            Color.accentRed.opacity(0.3),
                            lineWidth: 1
                        )
                    }
                }
            }
        }
        .padding(.horizontal, Space.pagePadding)
        .opacity(
            appeared ? 1 : 0
        )
        .offset(
            y: appeared ? 0 : 20
        )
        .animation(
            .appDramatic.delay(0.24),
            value: appeared
        )
    }
    
    // MARK: - Typed Guess
    
    private var typedGuessSection: some View {
        VStack(spacing: Space.md) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                
                Text("OR TYPE THE GUESS")
                    .font(
                        AppFont.label(size: 9)
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.25)
                    )
                    .tracking(1.5)
                    .fixedSize()
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
            }
            
            VStack(spacing: 10) {
                TextField(
                    "Type the word…",
                    text: $viewModel.mrWhiteGuessInput
                )
                .font(
                    .system(
                        size: 24,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
                .padding(.vertical, Space.md)
                .submitLabel(.done)
                .onSubmit {
                    submitTypedGuess()
                }
                
                Button {
                    submitTypedGuess()
                } label: {
                    ZStack {
                        if submitted {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.85)
                                
                                Text("CHECKING…")
                                    .font(
                                        AppFont.button(
                                            size: 13
                                        )
                                    )
                            }
                        } else {
                            Text("CHECK GUESS")
                                .font(
                                    AppFont.button(
                                        size: 13
                                    )
                                )
                                .tracking(1.5)
                        }
                    }
                    .foregroundStyle(
                        canSubmit && !submitted
                        ? .white
                        : Color.white.opacity(0.3)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        canSubmit && !submitted
                        ? Color.brandPink.opacity(0.14)
                        : Color.white.opacity(0.04)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Radius.md
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: Radius.md
                        )
                        .strokeBorder(
                            canSubmit && !submitted
                            ? Color.brandPink.opacity(0.35)
                            : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                    }
                }
                .disabled(
                    !canSubmit || submitted
                )
            }
        }
        .padding(.horizontal, Space.pagePadding)
        .padding(.top, Space.lg)
        .opacity(
            appeared ? 1 : 0
        )
        .offset(
            y: appeared ? 0 : 20
        )
        .animation(
            .appDramatic.delay(0.30),
            value: appeared
        )
    }
    
    // MARK: - Actions
    
    private func resolveLiveGuess(
        correct: Bool
    ) {
        focused = false
        Haptic.heavy()
        
        withAnimation(.appSpring) {
            viewModel.resolveMrWhiteGuess(
                correct: correct
            )
        }
    }
    
    private func submitTypedGuess() {
        guard canSubmit, !submitted else {
            return
        }
        
        focused = false
        submitted = true
        flashTrigger = true
        Haptic.heavy()
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.6
        ) {
            withAnimation(.appSpring) {
                viewModel.submitMrWhiteGuess()
            }
        }
    }
    
    // MARK: - Countdown
    
    private func startCountdown() {
        countdown = 3
        Haptic.timerTick()
        
        Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { timer in
            if countdown > 1 {
                countdown -= 1
                Haptic.timerTick()
            } else {
                timer.invalidate()
                Haptic.cardFlip()
                
                withAnimation(.appDramatic) {
                    showInput = true
                    appeared = true
                }
                
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.6
                ) {
                    focused = true
                }
            }
        }
    }
}
