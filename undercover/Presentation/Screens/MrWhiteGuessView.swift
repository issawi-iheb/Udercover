//
//  MrWhiteGuessView.swift
//  undercoverApp
//

import SwiftUI

public struct MrWhiteGuessView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var appeared = false
    @FocusState private var focused: Bool

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(Color.brandPink.opacity(0.12)).frame(width: 400).blur(radius: 100)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.4)

                VStack(spacing: 0) {
                    Spacer(minLength: 48)

                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.brandPink.opacity(0.14)).frame(width: 88, height: 88)
                            Text("🃏").font(.system(size: 44))
                        }
                        .scaleEffect(appeared ? 1 : 0.5).opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: appeared)

                        VStack(spacing: 6) {
                            Text("MR. WHITE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.brandPink).tracking(4)
                            Text(viewModel.isFinalMrWhiteDuel ? "Final Guess" : "One last chance")
                                .font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(.white)
                            Text(viewModel.isFinalMrWhiteDuel
                                 ? "Only you and the Undercover remain — guess the civilians' word to win."
                                 : "You were eliminated — guess the civilians' word to win.")
                                .font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.45))
                                .multilineTextAlignment(.center).padding(.horizontal, 32)
                        }
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
                        .animation(.spring().delay(0.22), value: appeared)
                    }

                    Spacer(minLength: 40)

                    // Input
                    VStack(spacing: 14) {
                        Text("WHAT IS THE CIVILIANS' WORD?")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.35)).tracking(2)

                        TextField("Type your guess…", text: $viewModel.mrWhiteGuessInput)
                            .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
                            .multilineTextAlignment(.center).autocorrectionDisabled()
                            .textInputAutocapitalization(.never).focused($focused)
                            .padding(.vertical, 18).padding(.horizontal, 20)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(
                                viewModel.mrWhiteGuessInput.isEmpty ? Color.appBorder : Color.brandPink.opacity(0.6),
                                lineWidth: 1.2
                            ))
                    }
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                    .animation(.spring().delay(0.35), value: appeared)

                    Spacer(minLength: 32)

                    Button {
                        focused = false
                        Haptic.heavy()
                        withAnimation { viewModel.submitMrWhiteGuess() }
                    } label: {
                        Text("SUBMIT GUESS")
                            .font(.system(size: 17, weight: .bold, design: .rounded)).tracking(1.5)
                            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(
                                viewModel.mrWhiteGuessInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.06)],
                                                     startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient.dangerGlow
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .glow(color: viewModel.mrWhiteGuessInput.isEmpty ? .clear : .brandPink)
                    }
                    .disabled(viewModel.mrWhiteGuessInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 28).padding(.bottom, geo.safeAreaInsets.bottom + 16)
                    .opacity(appeared ? 1 : 0).animation(.spring().delay(0.45), value: appeared)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
        }
    }
}
