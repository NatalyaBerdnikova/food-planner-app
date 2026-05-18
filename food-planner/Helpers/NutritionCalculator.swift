import Foundation

struct DailyNutrition: Equatable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    static let zero = DailyNutrition()

    static func from(dayPlan: DayPlan) -> DailyNutrition {
        dayPlan.meals.reduce(into: DailyNutrition()) { totals, meal in
            guard let recipe = meal.recipe else { return }
            totals.calories += recipe.caloriesPer100g
            totals.protein += recipe.proteinPer100g
            totals.fat += recipe.fatPer100g
            totals.carbs += recipe.carbsPer100g
        }
    }
}

extension DailyNutrition {
    var formattedSummary: String {
        "\(Int(calories.rounded())) ккал · Б \(formatMacro(protein)) · Ж \(formatMacro(fat)) · У \(formatMacro(carbs))"
    }

    private func formatMacro(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
