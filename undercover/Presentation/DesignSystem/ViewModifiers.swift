//
//  ViewModifiers.swift
//  undercoverApp
//
//  Every reusable visual modifier lives here.
//  Views only call .glow(), .glassCard(), .partyButton() etc.
//

import SwiftUI

// MARK: ─── Glow ──────────────────────────────────────────────────────────────

struct GlowModifier: ViewModifier {
    let color:  Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius * 0.4)
            .shadow(color: color.opacity(0.35), radius: radius)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 16) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: ─── Glass Card ────────────────────────────────────────────────────────

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let bordered:     Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appSurface)
                    .overlay(
                        Group {
                            if bordered {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .strokeBorder(Color.appBorder, lineWidth: 1)
                            }
                        }
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Radius.card, bordered: Bool = true) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, bordered: bordered))
    }
}

// MARK: ─── Party Button ──────────────────────────────────────────────────────
// A full-width gradient button with glow and press depression effect.

struct PartyButtonStyle: ButtonStyle {
    let gradient:  LinearGradient
    let glowColor: Color
    let disabled:  Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: glowColor.opacity(configuration.isPressed ? 0.2 : 0.5),
                radius: configuration.isPressed ? 4 : 14
            )
            .animation(.appSnap, value: configuration.isPressed)
    }
}

// MARK: ─── Shimmer ───────────────────────────────────────────────────────────

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                LinearGradient(
                    stops: [
                        .init(color: .clear,                 location: 0),
                        .init(color: .white.opacity(0.15),   location: 0.4),
                        .init(color: .white.opacity(0.3),    location: 0.5),
                        .init(color: .white.opacity(0.15),   location: 0.6),
                        .init(color: .clear,                 location: 1),
                    ],
                    startPoint: .init(x: phase, y: 0),
                    endPoint:   .init(x: phase + 1, y: 0)
                )
                .blendMode(.plusLighter)
            }
        )
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: ─── Typewriter Text ───────────────────────────────────────────────────

struct TypewriterText: View {
    let text:     String
    let font:     Font
    let color:    Color
    let duration: Double  // total duration for full text

    @State private var displayed = ""

    var body: some View {
        Text(displayed)
            .font(font)
            .foregroundStyle(color)
            .onAppear { animate() }
    }

    private func animate() {
        displayed = ""
        let chars = Array(text)
        let delay = duration / Double(max(chars.count, 1))
        for (i, char) in chars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * Double(i)) {
                displayed.append(char)
            }
        }
    }
}

// MARK: ─── Pulsing Ring ──────────────────────────────────────────────────────

struct PulsingRing: View {
    let color:  Color
    let size:   CGFloat
    @State private var scale:   CGFloat = 1.0
    @State private var opacity: Double  = 0.6

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    scale   = 1.6
                    opacity = 0
                }
            }
    }
}

// MARK: ─── Screen Flash ──────────────────────────────────────────────────────

struct ScreenFlash: View {
    let color: Color
    @Binding var trigger: Bool
    @State private var opacity: Double = 0

    var body: some View {
        color.opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, fired in
                guard fired else { return }
                opacity = 0.6
                withAnimation(.easeOut(duration: 0.5)) { opacity = 0 }
                trigger = false
            }
    }
}

// MARK: ─── Adaptive Screen Size ──────────────────────────────────────────────

enum ScreenSize {

    static func circleSize(for width: CGFloat) -> CGFloat {
        min(240, width * 0.60)
    }

    static func horizontalPadding(for width: CGFloat) -> CGFloat {
        min(24, width * 0.06)
    }
}
