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
    var displayName: String {
        switch self {
        case .gram: "г"
        case .kilogram: "кг"
        case .milliliter: "мл"
        case .liter: "л"
        case .piece: "шт"
        case .tablespoon: "ст. л."
        case .teaspoon: "ч. л."
        }
    }
}
