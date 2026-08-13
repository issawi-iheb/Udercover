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
                LinearGradient.brandBackground.ignoresSafeArea()

                Circle().fill(Color.brandPurple.opacity(0.22)).blur(radius: 120)
                    .offset(x: -120, y: -200)
                    .scaleEffect(appeared ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: appeared)

                Circle().fill(Color.brandPink.opacity(0.14)).blur(radius: 140)
                    .offset(x: 140, y: 220)
                    .scaleEffect(appeared ? 1.0 : 1.15)
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: appeared)

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 20) {
                        ZStack {
                            Circle().fill(Color.brandPurple.opacity(0.15)).frame(width: 110, height: 110)
                            Circle().strokeBorder(Color.brandPurple.opacity(0.3), lineWidth: 1).frame(width: 126, height: 126)
                            Text("🕵️").font(.system(size: 60))
                        }
                        .scaleEffect(appeared ? 1 : 0.7).opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1), value: appeared)

                        VStack(spacing: 8) {
                            Text("UNDERCOVER")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundStyle(.white).tracking(4)
                            Text("Blend in. Or get caught.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
                        .animation(.spring().delay(0.25), value: appeared)
                    }
                    .multilineTextAlignment(.center)

                    Spacer()

                    VStack(spacing: 14) {
                        NavigationLink { LobbyView() } label: {
                            HStack(spacing: 12) {
                                Text("PLAY").font(.system(size: 18, weight: .bold, design: .rounded)).tracking(2)
                                Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.white).frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient.brandGlow)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .glow(color: .brandPurple, radius: 14)
                        }
                        Text("3+ players required")
                            .font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.28))
                    }
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 24)
                    .animation(.spring().delay(0.4), value: appeared)

                    Spacer().frame(height: 60)
                }
            }
            .onAppear { appeared = true }
        }
    }
}
