//
//  HomeView.swift
//  undercoverApp
//

import SwiftUI

public struct HomeView: View {
    @State private var appeared  = false
    @State private var glowScale = false

    public var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.brandBackground.ignoresSafeArea()

                // Breathing ambient glows
                Circle().fill(Color.brandPurple.opacity(0.22)).blur(radius: 130)
                    .offset(x: -110, y: -220)
                    .scaleEffect(glowScale ? 1.15 : 0.88)
                    .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: glowScale)

                Circle().fill(Color.brandPink.opacity(0.14)).blur(radius: 150)
                    .offset(x: 130, y: 240)
                    .scaleEffect(glowScale ? 0.9 : 1.18)
                    .animation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true), value: glowScale)

                VStack(spacing: 0) {
                    Spacer()

                    // Identity block
                    VStack(spacing: 24) {
                        // Logo icon
                        ZStack {
                            // Outer ring
                            Circle()
                                .strokeBorder(Color.brandPurple.opacity(0.25), lineWidth: 1)
                                .frame(width: 130, height: 130)
                            // Inner fill
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.brandPurple.opacity(0.18), Color.brandPink.opacity(0.10)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 112, height: 112)
                            Text("🕵️")
                                .font(.system(size: 62))
                        }
                        .scaleEffect(appeared ? 1 : 0.65)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.58).delay(0.1), value: appeared)

                        VStack(spacing: 10) {
                            Text("UNDERCOVER")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .tracking(5)

                            // Tagline — typewriter on appear
                            if appeared {
                                TypewriterText(
                                    text:     "Blend in. Or get caught.",
                                    font:     AppFont.body(size: 16, weight: .medium),
                                    color:    Color.white.opacity(0.45),
                                    duration: 1.4
                                )
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)
                        .animation(.appDramatic.delay(0.25), value: appeared)
                    }
                    .multilineTextAlignment(.center)

                    Spacer()

                    // CTA
                    VStack(spacing: 14) {
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
                            .background(LinearGradient.brandGlow)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                            .glow(color: .brandPurple, radius: 20)
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
                appeared  = true
                glowScale = true
            }
        }
    }
}
