import Foundation

enum MeasurementUnit: String, Codable, CaseIterable {
    case gram
    case kilogram
    case milliliter
    case liter
    case piece
    case tablespoon
    case teaspoon
}

extension MeasurementUnit {
    var localizationKey: String {
        switch self {
        case .gram: "unit.gram"
        case .kilogram: "unit.kilogram"
        case .milliliter: "unit.milliliter"
        case .liter: "unit.liter"
        case .piece: "unit.piece"
        case .tablespoon: "unit.tablespoon"
        case .teaspoon: "unit.teaspoon"
        }
    }

    var displayName: LocalizedStringResource {
        switch self {
        case .gram: "unit.gram"
        case .kilogram: "unit.kilogram"
        case .milliliter: "unit.milliliter"
        case .liter: "unit.liter"
        case .piece: "unit.piece"
        case .tablespoon: "unit.tablespoon"
        case .teaspoon: "unit.teaspoon"
        }
    }

    var localizedName: String {
        String(localized: String.LocalizationValue(localizationKey))
    }
}
