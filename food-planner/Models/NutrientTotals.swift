import Foundation

struct NutrientTotals: Equatable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    var fiber: Double = 0
    var vitaminD3: Double = 0
    var calcium: Double = 0
    var magnesium: Double = 0
    var zinc: Double = 0
    var vitaminK: Double = 0
    var vitaminC: Double = 0
    var vitaminE: Double = 0
    var vitaminA: Double = 0
    var vitaminB6: Double = 0
    var vitaminB9: Double = 0
    var vitaminB12: Double = 0
    var selenium: Double = 0
    var chromium: Double = 0
    var iron: Double = 0
    var potassium: Double = 0
    var iodine: Double = 0

    static let zero = NutrientTotals()

    var macros: DailyNutrition {
        DailyNutrition(calories: calories, protein: protein, fat: fat, carbs: carbs)
    }

    static func + (lhs: NutrientTotals, rhs: NutrientTotals) -> NutrientTotals {
        NutrientTotals(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            fat: lhs.fat + rhs.fat,
            carbs: lhs.carbs + rhs.carbs,
            fiber: lhs.fiber + rhs.fiber,
            vitaminD3: lhs.vitaminD3 + rhs.vitaminD3,
            calcium: lhs.calcium + rhs.calcium,
            magnesium: lhs.magnesium + rhs.magnesium,
            zinc: lhs.zinc + rhs.zinc,
            vitaminK: lhs.vitaminK + rhs.vitaminK,
            vitaminC: lhs.vitaminC + rhs.vitaminC,
            vitaminE: lhs.vitaminE + rhs.vitaminE,
            vitaminA: lhs.vitaminA + rhs.vitaminA,
            vitaminB6: lhs.vitaminB6 + rhs.vitaminB6,
            vitaminB9: lhs.vitaminB9 + rhs.vitaminB9,
            vitaminB12: lhs.vitaminB12 + rhs.vitaminB12,
            selenium: lhs.selenium + rhs.selenium,
            chromium: lhs.chromium + rhs.chromium,
            iron: lhs.iron + rhs.iron,
            potassium: lhs.potassium + rhs.potassium,
            iodine: lhs.iodine + rhs.iodine
        )
    }

    func scaled(by factor: Double) -> NutrientTotals {
        NutrientTotals(
            calories: calories * factor,
            protein: protein * factor,
            fat: fat * factor,
            carbs: carbs * factor,
            fiber: fiber * factor,
            vitaminD3: vitaminD3 * factor,
            calcium: calcium * factor,
            magnesium: magnesium * factor,
            zinc: zinc * factor,
            vitaminK: vitaminK * factor,
            vitaminC: vitaminC * factor,
            vitaminE: vitaminE * factor,
            vitaminA: vitaminA * factor,
            vitaminB6: vitaminB6 * factor,
            vitaminB9: vitaminB9 * factor,
            vitaminB12: vitaminB12 * factor,
            selenium: selenium * factor,
            chromium: chromium * factor,
            iron: iron * factor,
            potassium: potassium * factor,
            iodine: iodine * factor
        )
    }

    func per100g(totalWeightGrams: Double) -> NutrientTotals {
        guard totalWeightGrams > 0 else { return .zero }
        return scaled(by: 100.0 / totalWeightGrams)
    }
}
