//
//  HomeView.swift
//  undercoverApp
//

import SwiftUI

public struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    public var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.brandBackground
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 24) {
                        MrWhiteDrawing()
                            .frame(width: 190, height: 190)
                            .scaleEffect(
                                reduceMotion
                                    ? 1
                                    : (appeared ? 1 : 0.85)
                            )
                            .opacity(appeared ? 1 : 0)
                            .accessibilityHidden(true)
                            .animation(
                                reduceMotion
                                    ? .none
                                    : .spring(
                                        response: 0.7,
                                        dampingFraction: 0.58
                                    ).delay(0.1),
                                value: appeared
                            )

                        VStack(spacing: 10) {
                            Text("UNDERCOVER")
                                .font(
                                    .system(
                                        size: 40,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.white)
                                .tracking(5)
                                .accessibilityAddTraits(.isHeader)

                            if appeared && !reduceMotion {
                                TypewriterText(
                                    text: "Blend in. Or get caught.",
                                    font: AppFont.body(
                                        size: 16,
                                        weight: .medium
                                    ),
                                    color: Color.white.opacity(0.45),
                                    duration: 1.4
                                )
                            } else {
                                Text("Blend in. Or get caught.")
                                    .font(
                                        AppFont.body(
                                            size: 16,
                                            weight: .medium
                                        )
                                    )
                                    .foregroundStyle(
                                        Color.white.opacity(0.45)
                                    )
                            }
                        }
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(
                            y: reduceMotion
                                ? 0
                                : (appeared ? 0 : 18)
                        )
                        .animation(
                            reduceMotion
                                ? .none
                                : .appDramatic.delay(0.25),
                            value: appeared
                        )
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        NavigationLink {
                            LobbyView()
                        } label: {
                            HStack(spacing: 14) {
                                Text("PLAY")
                                    .font(
                                        .system(
                                            size: 20,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                                    .tracking(3)

                                Image(
                                    systemName: "arrow.right.circle.fill"
                                )
                                .font(.system(size: 22))
                                .accessibilityHidden(true)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient.brandGlow
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: Radius.md
                                )
                            )
                            .glow(
                                color: .brandPurple,
                                radius: 10
                            )
                        }
                        .buttonStyle(
                            PartyButtonStyle(
                                gradient: .brandGlow,
                                glowColor: .brandPurple,
                                disabled: false
                            )
                        )
                        .accessibilityLabel("PLAY")

                        Text("3 or more players required")
                            .font(AppFont.label(size: 11))
                            .foregroundStyle(
                                Color.white.opacity(0.22)
                            )
                            .tracking(1)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Space.xl)
                    .opacity(appeared ? 1 : 0)
                    .offset(
                        y: reduceMotion
                            ? 0
                            : (appeared ? 0 : 28)
                    )
                    .animation(
                        reduceMotion
                            ? .none
                            : .appDramatic.delay(0.42),
                        value: appeared
                    )

                    Spacer()
                        .frame(height: 60)
                }
            }
            .onAppear {
                appeared = true
            }
        }
    }
}
