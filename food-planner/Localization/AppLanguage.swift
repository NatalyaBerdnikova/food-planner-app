import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case russian = "ru"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    /// `nil` — следовать языку системы устройства.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .english: Locale(identifier: "en")
        case .russian: Locale(identifier: "ru")
        }
    }

    var displayName: LocalizedStringResource {
        switch self {
        case .system: "language.system"
        case .english: "language.english"
        case .russian: "language.russian"
        }
    }
}

extension View {
    @ViewBuilder
    func applyAppLanguage(_ language: AppLanguage) -> some View {
        if let locale = language.locale {
            environment(\.locale, locale)
                .id("locale-\(locale.identifier)")
        } else {
            id("locale-system")
        }
    }
}
