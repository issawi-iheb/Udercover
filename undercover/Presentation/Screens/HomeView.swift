//
//  HomeView.swift
//  undercoverApp
//

import SwiftUI

public struct HomeView: View {
    @State private var appeared = false

    public var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Dark background only — no breathing glows
                LinearGradient.brandBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Identity block — centered, breathes on its own via animation
                    VStack(spacing: 24) {
                        // Logo: MrWhiteDrawing (handles its own animation)
                        MrWhiteDrawing()
                            .frame(width: 190, height: 190)
                            .scaleEffect(appeared ? 1 : 0.85)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.7, dampingFraction: 0.58).delay(0.1),
                                value: appeared
                            )

                        VStack(spacing: 10) {
                            Text("UNDERCOVER")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .tracking(5)

                            // Tagline — animated typewriter effect
                            if appeared {
                                TypewriterText(
                                    text:     "Blend in. Or get caught.",
                                    font:     AppFont.body(size: 16, weight: .medium),
                                    color:    Color.white.opacity(0.45),
                                    duration: 1.4
                                )
                            }
                        }
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)
                        .animation(.appDramatic.delay(0.25), value: appeared)
                    }

                    Spacer()

                    // CTA section — clear, primary action
                    VStack(spacing: 14) {
                        // ✅ PLAY button — primary, unmissable
                        NavigationLink { LobbyView() } label: {
                            HStack(spacing: 14) {
                                Text("PLAY")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .tracking(3)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 22))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            // ✅ Functional glow: indicates primary action
                            .background(LinearGradient.brandGlow)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .glow(color: .brandPurple, radius: 10)
                        }
                        .buttonStyle(PartyButtonStyle(gradient: .brandGlow, glowColor: .brandPurple, disabled: false))

                        Text("3 or more players required")
                            .font(AppFont.label(size: 11))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .tracking(1)
                    }
                    .padding(.horizontal, Space.xl)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 28)
                    .animation(.appDramatic.delay(0.42), value: appeared)

                    Spacer().frame(height: 60)
                }
            }
            .onAppear {
                appeared = true
            }
        }
    }
}
