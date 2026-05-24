import SwiftUI

enum MacroLabelStyle {
    case compact
    case full

    var kcalTitle: LocalizedStringResource {
        switch self {
        case .compact: "nutrition.macro.kcal"
        case .full: "nutrition.macro.kcal.full"
        }
    }

    var proteinTitle: LocalizedStringResource {
        switch self {
        case .compact: "nutrition.macro.protein"
        case .full: "nutrition.macro.protein.full"
        }
    }

    var fatTitle: LocalizedStringResource {
        switch self {
        case .compact: "nutrition.macro.fat"
        case .full: "nutrition.macro.fat.full"
        }
    }

    var carbsTitle: LocalizedStringResource {
        switch self {
        case .compact: "nutrition.macro.carbs"
        case .full: "nutrition.macro.carbs.full"
        }
    }
}
