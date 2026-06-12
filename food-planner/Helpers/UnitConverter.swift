import Foundation

enum UnitConverter {
    static func grams(
        quantity: Double,
        unit: MeasurementUnit,
        product: FoodProduct?
    ) -> Double {
        switch unit {
        case .gram:
            return quantity
        case .kilogram:
            return quantity * 1000
        case .milliliter:
            return quantity
        case .liter:
            return quantity * 1000
        case .piece:
            return quantity * (product?.defaultPieceWeightGrams ?? 100)
        case .tablespoon:
            return quantity * 15
        case .teaspoon:
            return quantity * 5
        }
    }

    static func quantity(
        fromGrams grams: Double,
        unit: MeasurementUnit,
        product: FoodProduct?
    ) -> Double {
        switch unit {
        case .gram:
            return grams
        case .kilogram:
            return grams / 1000
        case .milliliter:
            return grams
        case .liter:
            return grams / 1000
        case .piece:
            return grams / (product?.defaultPieceWeightGrams ?? 100)
        case .tablespoon:
            return grams / 15
        case .teaspoon:
            return grams / 5
        }
    }
}
