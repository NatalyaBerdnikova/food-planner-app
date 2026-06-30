import Foundation

/// Микронутриенты на 100 г продукта / в сумме по рецепту.
enum MicronutrientKind: String, CaseIterable, Identifiable {
    case fiber
    case vitaminD3
    case calcium
    case magnesium
    case zinc
    case vitaminK
    case vitaminC
    case vitaminE
    case vitaminA
    case vitaminB6
    case vitaminB9
    case vitaminB12
    case selenium
    case chromium
    case iron
    case potassium
    case iodine

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .fiber: "micro.fiber"
        case .vitaminD3: "micro.vitaminD3"
        case .calcium: "micro.calcium"
        case .magnesium: "micro.magnesium"
        case .zinc: "micro.zinc"
        case .vitaminK: "micro.vitaminK"
        case .vitaminC: "micro.vitaminC"
        case .vitaminE: "micro.vitaminE"
        case .vitaminA: "micro.vitaminA"
        case .vitaminB6: "micro.vitaminB6"
        case .vitaminB9: "micro.vitaminB9"
        case .vitaminB12: "micro.vitaminB12"
        case .selenium: "micro.selenium"
        case .chromium: "micro.chromium"
        case .iron: "micro.iron"
        case .potassium: "micro.potassium"
        case .iodine: "micro.iodine"
        }
    }

    var displayName: String {
        String(localized: String.LocalizationValue(localizationKey))
    }

    var unitLocalizationKey: String {
        switch self {
        case .fiber, .vitaminE, .vitaminB6, .iron:
            "nutrition.unit.g"
        case .calcium, .magnesium, .zinc, .vitaminC, .potassium:
            "nutrition.unit.mg"
        case .vitaminD3, .vitaminK, .vitaminA, .vitaminB9, .vitaminB12, .selenium, .chromium, .iodine:
            "nutrition.unit.mcg"
        }
    }

    /// Суточная норма для взрослого (ориентир для шкалы, не персональная цель).
    var dailyTarget: Double {
        switch self {
        case .fiber: 30
        case .vitaminD3: 15
        case .calcium: 1000
        case .magnesium: 400
        case .zinc: 11
        case .vitaminK: 90
        case .vitaminC: 90
        case .vitaminE: 15
        case .vitaminA: 800
        case .vitaminB6: 1.5
        case .vitaminB9: 400
        case .vitaminB12: 2.4
        case .selenium: 55
        case .chromium: 35
        case .iron: 15
        case .potassium: 3000
        case .iodine: 150
        }
    }
}

extension NutrientTotals {
    func value(for kind: MicronutrientKind) -> Double {
        switch kind {
        case .fiber: fiber
        case .vitaminD3: vitaminD3
        case .calcium: calcium
        case .magnesium: magnesium
        case .zinc: zinc
        case .vitaminK: vitaminK
        case .vitaminC: vitaminC
        case .vitaminE: vitaminE
        case .vitaminA: vitaminA
        case .vitaminB6: vitaminB6
        case .vitaminB9: vitaminB9
        case .vitaminB12: vitaminB12
        case .selenium: selenium
        case .chromium: chromium
        case .iron: iron
        case .potassium: potassium
        case .iodine: iodine
        }
    }
}
