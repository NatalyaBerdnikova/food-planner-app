import SwiftUI

enum AppColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "appColorScheme"

    var id: String { rawValue }

    /// `nil` — следовать теме системы.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var displayName: LocalizedStringResource {
        switch self {
        case .system: "theme.system"
        case .light: "theme.light"
        case .dark: "theme.dark"
        }
    }
}

extension View {
    @ViewBuilder
    func applyAppColorScheme(_ scheme: AppColorScheme) -> some View {
        if let colorScheme = scheme.colorScheme {
            preferredColorScheme(colorScheme)
        } else {
            self
        }
    }
}
