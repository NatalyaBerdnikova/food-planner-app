import Foundation

struct NutrientTotals: Equatable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    var fiber: Double = 0
    var sugar: Double = 0
    var saturatedFat: Double = 0
    var sodium: Double = 0
    var potassium: Double = 0
    var calcium: Double = 0
    var iron: Double = 0
    var magnesium: Double = 0
    var zinc: Double = 0
    var vitaminC: Double = 0
    var vitaminD: Double = 0
    var vitaminB12: Double = 0
    var folate: Double = 0

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
            sugar: lhs.sugar + rhs.sugar,
            saturatedFat: lhs.saturatedFat + rhs.saturatedFat,
            sodium: lhs.sodium + rhs.sodium,
            potassium: lhs.potassium + rhs.potassium,
            calcium: lhs.calcium + rhs.calcium,
            iron: lhs.iron + rhs.iron,
            magnesium: lhs.magnesium + rhs.magnesium,
            zinc: lhs.zinc + rhs.zinc,
            vitaminC: lhs.vitaminC + rhs.vitaminC,
            vitaminD: lhs.vitaminD + rhs.vitaminD,
            vitaminB12: lhs.vitaminB12 + rhs.vitaminB12,
            folate: lhs.folate + rhs.folate
        )
    }

    func scaled(by factor: Double) -> NutrientTotals {
        NutrientTotals(
            calories: calories * factor,
            protein: protein * factor,
            fat: fat * factor,
            carbs: carbs * factor,
            fiber: fiber * factor,
            sugar: sugar * factor,
            saturatedFat: saturatedFat * factor,
            sodium: sodium * factor,
            potassium: potassium * factor,
            calcium: calcium * factor,
            iron: iron * factor,
            magnesium: magnesium * factor,
            zinc: zinc * factor,
            vitaminC: vitaminC * factor,
            vitaminD: vitaminD * factor,
            vitaminB12: vitaminB12 * factor,
            folate: folate * factor
        )
    }

    func per100g(totalWeightGrams: Double) -> NutrientTotals {
        guard totalWeightGrams > 0 else { return .zero }
        return scaled(by: 100.0 / totalWeightGrams)
    }
}
