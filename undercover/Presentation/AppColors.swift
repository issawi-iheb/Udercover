//
//  AppColors.swift
//  undercoverApp
//
//  Brand colors, gradients, and SwiftUI view modifiers used across the app.
//  Add a Color Set in Assets.xcassets for each named color,
//  or use the hardcoded hex values below.
//

import SwiftUI

// MARK: - Brand colors

extension Color {
    // Core brand
    static let brandPurple = Color(hex: "#7C5CBF")
    static let brandPink   = Color(hex: "#E05C8A")

    // Semantic
    static let accentGreen = Color(hex: "#4CAF82")
    static let accentAmber = Color(hex: "#F5A623")
    static let accentRed   = Color(hex: "#E05252")

    // Surfaces
    static let appBackground = Color(hex: "#0D0D14")
    static let appSurface    = Color(hex: "#16161F")
    static let appBorder     = Color(white: 1, opacity: 0.08)

    // Avatar palette (cycles by player index)
    static func avatar(for index: Int) -> Color {
        let palette: [Color] = [
            Color(hex: "#7C5CBF"),
            Color(hex: "#E05C8A"),
            Color(hex: "#4CAF82"),
            Color(hex: "#F5A623"),
            Color(hex: "#5BB8E8"),
            Color(hex: "#E07C5C"),
            Color(hex: "#A05CBF"),
            Color(hex: "#5CBF8A"),
        ]
        return palette[index % palette.count]
    }

    // Hex initialiser
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let brandBackground = LinearGradient(
        colors: [Color(hex: "#0D0D14"), Color(hex: "#12101E")],
        startPoint: .top, endPoint: .bottom
    )
    static let brandGlow = LinearGradient(
        colors: [Color.brandPurple, Color.brandPink],
        startPoint: .leading, endPoint: .trailing
    )
    static let dangerGlow = LinearGradient(
        colors: [Color.brandPink, Color(hex: "#BF3A3A")],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - View modifiers

struct GlowModifier: ViewModifier {
    let color:  Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color.opacity(0.55), radius: radius / 2)
                .shadow(color: color.opacity(0.30), radius: radius)
    }
}

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.appBorder, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 16) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
