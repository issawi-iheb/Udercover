//
//  DesignTokens.swift
//  undercoverApp
//
//  Single source of truth for every visual constant in the app.
//  No hardcoded hex strings anywhere else.
//

import SwiftUI

// MARK: ─── Colors ────────────────────────────────────────────────────────────

extension Color {

    // Brand
    static let brandPurple   = Color(hex: "#7C5CBF")
    static let brandPink     = Color(hex: "#E05C8A")
    static let brandPurpleLight = Color(hex: "#9B7ED4")

    // Semantic
    static let accentGreen   = Color(hex: "#4CAF82")
    static let accentAmber   = Color(hex: "#F5A623")
    static let accentRed     = Color(hex: "#E05252")
    static let accentWhite   = Color(hex: "#F0EEF8")   // Mr. White palette

    // Surfaces
    static let appBackground = Color(hex: "#0A0A12")
    static let appSurface    = Color(hex: "#13131E")
    static let appSurface2   = Color(hex: "#1C1C2E")   // elevated surface
    static let appBorder     = Color(white: 1, opacity: 0.09)
    static let appBorderHot  = Color(white: 1, opacity: 0.18)  // selected/active

    // Voting danger
    static let dangerRed     = Color(hex: "#C0392B")

    // Avatar palette — 8 distinct colors cycling by player index
    static func avatar(for index: Int) -> Color {
        let palette: [Color] = [
            Color(hex: "#7C5CBF"),   // purple
            Color(hex: "#E05C8A"),   // pink
            Color(hex: "#4CAF82"),   // green
            Color(hex: "#F5A623"),   // amber
            Color(hex: "#5BB8E8"),   // sky
            Color(hex: "#E07C5C"),   // coral
            Color(hex: "#A05CBF"),   // violet
            Color(hex: "#5CBF8A"),   // mint
        ]
        return palette[abs(index) % palette.count]
    }

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: ─── Gradients ─────────────────────────────────────────────────────────

extension LinearGradient {
    static let brandBackground = LinearGradient(
        colors: [Color(hex: "#0A0A12"), Color(hex: "#10101E")],
        startPoint: .top, endPoint: .bottom
    )
    static let brandGlow = LinearGradient(
        colors: [Color.brandPurple, Color.brandPink],
        startPoint: .leading, endPoint: .trailing
    )
    static let brandGlowVertical = LinearGradient(
        colors: [Color.brandPurple, Color.brandPink],
        startPoint: .top, endPoint: .bottom
    )
    static let dangerGlow = LinearGradient(
        colors: [Color.brandPink, Color(hex: "#BF3A3A")],
        startPoint: .leading, endPoint: .trailing
    )
    static let dangerGlowStrong = LinearGradient(
        colors: [Color(hex: "#E03030"), Color(hex: "#A01010")],
        startPoint: .leading, endPoint: .trailing
    )
    static let mrWhiteGlow = LinearGradient(
        colors: [Color(hex: "#E8E6F8"), Color(hex: "#C8C0F0")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let surfaceGlow = LinearGradient(
        colors: [Color.brandPurple.opacity(0.15), Color.brandPink.opacity(0.08)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension RadialGradient {
    static func spotlight(color: Color, radius: CGFloat = 200) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(0.35), color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
    }
}

// MARK: ─── Typography ────────────────────────────────────────────────────────

/// Centralised font definitions. All text in the app should use these.
enum AppFont {

    // Game words — large, impactful, readable from a distance
    static func gameWord(size: CGFloat = 72) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    // Section labels — monospaced tracking caps
    static func label(size: CGFloat = 11) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    // Player names — prominent
    static func playerName(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    // Body
    static func body(size: CGFloat = 15, weight: UIFont.Weight = .regular) -> Font {
        .system(size: size, weight: Font.Weight(weight), design: .rounded)
    }

    // Button
    static func button(size: CGFloat = 17) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Huge timer / countdown
    static func timer(size: CGFloat = 108) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
}

private extension Font.Weight {
    init(_ weight: UIFont.Weight) {
        switch weight {
        case .ultraLight: self = .ultraLight
        case .thin:       self = .thin
        case .light:      self = .light
        case .regular:    self = .regular
        case .medium:     self = .medium
        case .semibold:   self = .semibold
        case .bold:       self = .bold
        case .heavy:      self = .heavy
        case .black:      self = .black
        default:          self = .regular
        }
    }
}

// MARK: ─── Spacing ───────────────────────────────────────────────────────────

enum Space {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48

    /// Safe horizontal page margin
    static let pagePadding: CGFloat = 24
}

// MARK: ─── Corner Radii ──────────────────────────────────────────────────────

enum Radius {
    static let sm:   CGFloat = 10
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 22
    static let xl:   CGFloat = 28
    static let card: CGFloat = 24
    static let pill: CGFloat = 100
}

// MARK: ─── PairDifficulty UI ─────────────────────────────────────────────────

extension PairDifficulty {
    var color: Color {
        switch self {
        case .easy:   return .accentGreen
        case .medium: return .accentAmber
        case .hard:   return .accentRed
        }
    }
    var emoji: String {
        switch self {
        case .easy:   return "🟢"
        case .medium: return "🟡"
        case .hard:   return "🔴"
        }
    }
}

// MARK: ─── AppLanguage layout ────────────────────────────────────────────────

extension AppLanguage {
    var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }
}
