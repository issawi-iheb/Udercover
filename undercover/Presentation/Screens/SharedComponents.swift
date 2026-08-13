//
//  SharedComponents.swift
//  undercoverApp
//

import SwiftUI

// MARK: - WordLabel

public struct WordLabel: View {
    public let title: String
    public let word:  String
    public let color: Color

    public var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(0.65)).tracking(2)
            Text(word)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(color).multilineTextAlignment(.center)
        }
    }
}

// MARK: - RoundBadge

public struct RoundBadge: View {
    public let round:    Int
    public let language: AppLanguage

    public var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.brandPurple.opacity(0.2)).frame(width: 28, height: 28)
                Image(systemName: "flag.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.brandPurple)
            }
            Text(language.strings.round(round))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white).tracking(language.isRTL ? 0 : 1.5)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(ZStack {
            Color.appSurface
            LinearGradient(colors: [Color.brandPurple.opacity(0.18), Color.brandPink.opacity(0.10)],
                           startPoint: .leading, endPoint: .trailing)
        })
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(
            LinearGradient(colors: [Color.brandPurple.opacity(0.5), Color.brandPink.opacity(0.3)],
                           startPoint: .leading, endPoint: .trailing), lineWidth: 1))
        .shadow(color: Color.brandPurple.opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

// MARK: - DifficultyBadge

public struct DifficultyBadge: View {
    public let difficulty: PairDifficulty

    public var body: some View {
        HStack(spacing: 5) {
            Text(difficulty.emoji).font(.system(size: 12))
            Text(difficulty.label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(difficulty.color).tracking(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(difficulty.color.opacity(0.12)).clipShape(Capsule())
        .overlay(Capsule().strokeBorder(difficulty.color.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - PrimaryButton / SecondaryButton

public struct PrimaryButton: View {
    let label: String; let icon: String?
    let gradient: LinearGradient; let glowColor: Color; let action: () -> Void

    public init(_ label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        // Use internal defaults inside the initializer body to avoid access control issues
        self.gradient = .brandGlow
        self.glowColor = .brandPurple
        self.action = action
    }

    public init(_ label: String, icon: String? = nil, gradient: LinearGradient, glowColor: Color, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.gradient = gradient
        self.glowColor = glowColor
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .bold)) }
                Text(label).font(.system(size: 17, weight: .bold, design: .rounded)).tracking(1.5)
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(gradient).clipShape(RoundedRectangle(cornerRadius: 18)).glow(color: glowColor)
        }
    }
}

public struct SecondaryButton: View {
    let label: String; let icon: String?; let action: () -> Void

    public init(_ label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label; self.icon = icon; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .bold)) }
                Text(label).font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color.white.opacity(0.65)).frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Color.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.appBorder, lineWidth: 1))
        }
    }
}

// MARK: - PairDifficulty UI extensions

extension PairDifficulty {
    public var color: Color {
        switch self {
        case .easy:   return .accentGreen
        case .medium: return .accentAmber
        case .hard:   return .accentRed
        }
    }
    public var emoji: String {
        switch self {
        case .easy:   return "🟢"
        case .medium: return "🟡"
        case .hard:   return "🔴"
        }
    }
}

// MARK: - AppLanguage layout direction

import UIKit
extension AppLanguage {
    public var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }
}

