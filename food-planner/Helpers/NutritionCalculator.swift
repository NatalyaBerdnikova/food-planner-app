import Foundation
import SwiftData

struct DailyNutrition: Equatable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    static let zero = DailyNutrition()
}

struct RecipeNutrition {
    let total: NutrientTotals
    let totalWeightGrams: Double
    let per100g: NutrientTotals
}

enum NutritionCalculator {
    static func from(dayPlan: DayPlan) -> DailyNutrition {
        dayPlan.meals.reduce(into: DailyNutrition()) { totals, meal in
            guard let recipe = meal.recipe else { return }
            let nutrition = recipeNutrition(recipe)
            totals.calories += nutrition.total.calories
            totals.protein += nutrition.total.protein
            totals.fat += nutrition.total.fat
            totals.carbs += nutrition.total.carbs
        }
    }

    static func recipeNutrition(_ recipe: Recipe) -> RecipeNutrition {
        var totalWeight = 0.0
        var totals = NutrientTotals.zero

        for ingredient in recipe.ingredients {
            guard let product = ingredient.foodProduct else { continue }
            let grams = UnitConverter.grams(
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                product: product
            )
            guard grams > 0 else { continue }
            totalWeight += grams
            totals = totals + product.nutrientsPer100g.scaled(by: grams / 100.0)
        }

        let per100g = totals.per100g(totalWeightGrams: totalWeight)
        return RecipeNutrition(total: totals, totalWeightGrams: totalWeight, per100g: per100g)
    }

    static func ingredientNutrition(_ ingredient: Ingredient) -> NutrientTotals {
        guard let product = ingredient.foodProduct else { return .zero }
        let grams = UnitConverter.grams(
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            product: product
        )
        guard grams > 0 else { return .zero }
        return product.nutrientsPer100g.scaled(by: grams / 100.0)
    }
}

extension Recipe {
    func recalculateNutrition() {
        let nutrition = NutritionCalculator.recipeNutrition(self)
        caloriesPer100g = nutrition.per100g.calories
        proteinPer100g = nutrition.per100g.protein
        fatPer100g = nutrition.per100g.fat
        carbsPer100g = nutrition.per100g.carbs
    }
}
