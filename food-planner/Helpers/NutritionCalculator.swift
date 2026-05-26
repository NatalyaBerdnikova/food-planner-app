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

    /// Среднее КБЖУ в день за неделю (по всем дням плана, включая пустые).
    static func averageDaily(for weekPlan: WeekPlan) -> DailyNutrition {
        let dayPlans = weekPlan.dayPlans.sorted { $0.date < $1.date }
        guard !dayPlans.isEmpty else { return .zero }

        let weekTotal = dayPlans.reduce(into: DailyNutrition()) { totals, dayPlan in
            let daily = from(dayPlan: dayPlan)
            totals.calories += daily.calories
            totals.protein += daily.protein
            totals.fat += daily.fat
            totals.carbs += daily.carbs
        }

        let dayCount = Double(dayPlans.count)
        return DailyNutrition(
            calories: weekTotal.calories / dayCount,
            protein: weekTotal.protein / dayCount,
            fat: weekTotal.fat / dayCount,
            carbs: weekTotal.carbs / dayCount
        )
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

    static func nutritionPerServing(for recipe: Recipe) -> DailyNutrition {
        let nutrition = recipeNutrition(recipe)
        let servings = max(Double(recipe.servings), 1)
        return DailyNutrition(
            calories: nutrition.total.calories / servings,
            protein: nutrition.total.protein / servings,
            fat: nutrition.total.fat / servings,
            carbs: nutrition.total.carbs / servings
        )
    }

    static func weightPerServingGrams(for recipe: Recipe) -> Double {
        recipeNutrition(recipe).totalWeightGrams / max(Double(recipe.servings), 1)
    }

    static func displayQuantity(
        for ingredient: Ingredient,
        displayPortions: Double,
        recipeServings: Int
    ) -> Double {
        let base = max(Double(recipeServings), 1)
        return ingredient.quantity * displayPortions / base
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
