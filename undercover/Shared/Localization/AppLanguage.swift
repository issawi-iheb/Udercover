//
//  AppLanguage.swift
//  undercoverApp
//

import Foundation

/// rawValue = JSON key used in words.json and API prompts ("en", "fr", "ar", "es", "tn").
public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english  = "en"
    case french   = "fr"
    case arabic   = "ar"
    case spanish  = "es"
    case tunisian = "tn"

    public var displayName: String {
        switch self {
        case .english:  return "English"
        case .french:   return "Français"
        case .arabic:   return "العربية"
        case .spanish:  return "Español"
        case .tunisian: return "تونسي"
        }
    }

    public var promptLabel: String {
        switch self {
        case .english:  return "English"
        case .french:   return "French"
        case .arabic:   return "Arabic (Modern Standard)"
        case .spanish:  return "Spanish"
        case .tunisian: return "Tunisian Arabic (Darija)"
        }
    }

    public var isRTL: Bool { self == .arabic || self == .tunisian }

    public var strings: AppStrings { AppStrings(language: self) }
}
