import Foundation
import SwiftData

enum OnboardingDayPreviewFactory {
    private static let fallbackCatalogIds = ["recipe_01", "recipe_10", "recipe_18"]
    private static let minimumMacroCoverage = 0.90
    private static let maximumMacroCoverage = 1.05
    private static let poolLimit = 10

    @MainActor
    static func makeDayPlan(
        in context: ModelContext,
        matching target: DailyNutrition,
        micronutrientFocus: [MicronutrientKind]
    ) -> DayPlan? {
        _ = micronutrientFocus
        FoodCatalogSeeder.seedIfNeeded(in: context)
        RecipeCatalogStore.seedIfNeeded(in: context)

        let candidates = candidateRecipes(in: context)
        let selection = selectRecipes(from: candidates, matching: target)
            ?? fallbackSelection(in: context, matching: target)
        guard let selection else { return nil }

        let today = Calendar.current.startOfDay(for: .now)
        let dayPlan = DayPlan(date: today)
        context.insert(dayPlan)

        let mealTypes: [MealType] = [.breakfast, .lunch, .dinner]
        var meals: [Meal] = []
        for index in mealTypes.indices {
            let clone = cloneRecipe(selection.sources[index], factor: selection.scale, in: context)
            let meal = Meal(
                mealType: mealTypes[index],
                date: today,
                recipe: clone,
                dayPlan: dayPlan
            )
            context.insert(meal)
            meals.append(meal)
        }
        dayPlan.meals = meals
        return dayPlan
    }

    @MainActor
    static func discard(_ dayPlan: DayPlan, in context: ModelContext) {
        let recipes = dayPlan.meals.compactMap(\.recipe)
        for recipe in recipes {
            context.delete(recipe)
        }
        context.delete(dayPlan)
    }

    private struct Selection {
        let sources: [Recipe]
        let scale: Double
    }

    @MainActor
    private static func candidateRecipes(in context: ModelContext) -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { recipe in
            guard recipe.isCatalogRecipe, recipe.isVisibleInApp else { return false }
            return NutritionCalculator.nutritionPerServing(for: recipe).calories > 50
        }
    }

    @MainActor
    private static func selectRecipes(
        from candidates: [Recipe],
        matching target: DailyNutrition
    ) -> Selection? {
        guard !candidates.isEmpty, target.calories > 0 else { return nil }

        let breakfastPool = pool(for: .breakfast, from: candidates)
        let lunchPool = pool(for: .lunch, from: candidates)
        let dinnerPool = pool(for: .dinner, from: candidates)

        var best: (Selection, Double)?

        for breakfast in breakfastPool {
            for lunch in lunchPool {
                for dinner in dinnerPool {
                    let ids = [breakfast.persistentModelID, lunch.persistentModelID, dinner.persistentModelID]
                    guard Set(ids).count == 3 else { continue }

                    let base = macrosSum([breakfast, lunch, dinner])
                    guard base.calories > 0 else { continue }

                    let scale = clampedScale(target.calories / base.calories)
                    let scaled = scaleMacros(base, by: scale)
                    let score = fitness(actual: scaled, target: target)
                    if best == nil || score > best!.1 {
                        best = (
                            Selection(sources: [breakfast, lunch, dinner], scale: scale),
                            score
                        )
                    }
                }
            }
        }

        return best?.0
    }

    @MainActor
    private static func fallbackSelection(
        in context: ModelContext,
        matching target: DailyNutrition
    ) -> Selection? {
        let sources = fallbackCatalogIds.compactMap { catalogRecipe(id: $0, in: context) }
        guard sources.count == 3 else { return nil }
        let base = macrosSum(sources)
        guard base.calories > 0 else {
            return Selection(sources: sources, scale: 1)
        }
        return Selection(
            sources: sources,
            scale: clampedScale(target.calories / base.calories)
        )
    }

    private static func pool(for mealType: MealType, from candidates: [Recipe]) -> [Recipe] {
        let tagged = candidates.filter {
            $0.mealTypeTags.isEmpty || $0.mealTypeTags.contains(mealType)
        }
        let source = tagged.isEmpty ? candidates : tagged
        return Array(
            source
                .sorted { lhs, rhs in
                    let left = NutritionCalculator.nutritionPerServing(for: lhs)
                    let right = NutritionCalculator.nutritionPerServing(for: rhs)
                    let leftDensity = left.protein / max(left.calories, 1)
                    let rightDensity = right.protein / max(right.calories, 1)
                    if leftDensity != rightDensity {
                        return leftDensity > rightDensity
                    }
                    return left.calories > right.calories
                }
                .prefix(poolLimit)
        )
    }

    private static func macrosSum(_ recipes: [Recipe]) -> DailyNutrition {
        recipes.reduce(into: DailyNutrition.zero) { partial, recipe in
            let nutrition = NutritionCalculator.nutritionPerServing(for: recipe)
            partial.calories += nutrition.calories
            partial.protein += nutrition.protein
            partial.fat += nutrition.fat
            partial.carbs += nutrition.carbs
        }
    }

    private static func scaleMacros(_ nutrition: DailyNutrition, by factor: Double) -> DailyNutrition {
        DailyNutrition(
            calories: nutrition.calories * factor,
            protein: nutrition.protein * factor,
            fat: nutrition.fat * factor,
            carbs: nutrition.carbs * factor
        )
    }

    private static func clampedScale(_ scale: Double) -> Double {
        min(max(scale, 0.55), 2.4)
    }

    /// Higher is better. Strongly prefers every macro in 90…105%.
    private static func fitness(actual: DailyNutrition, target: DailyNutrition) -> Double {
        let ratios = [
            ratio(actual.calories, target.calories),
            ratio(actual.protein, target.protein),
            ratio(actual.fat, target.fat),
            ratio(actual.carbs, target.carbs),
        ]
        let minimum = ratios.min() ?? 0
        let maximum = ratios.max() ?? 0
        let average = ratios.reduce(0, +) / Double(ratios.count)

        if minimum >= minimumMacroCoverage && maximum <= maximumMacroCoverage {
            return 2_000 + minimum * 100 + (1 - abs(average - 1)) * 20
        }
        if minimum >= minimumMacroCoverage {
            return 1_000 + minimum * 100 - max(0, maximum - maximumMacroCoverage) * 200
        }
        return minimum * 100 - max(0, maximum - maximumMacroCoverage) * 50
    }

    private static func ratio(_ actual: Double, _ target: Double) -> Double {
        guard target > 0 else { return 1 }
        return actual / target
    }

    @MainActor
    private static func catalogRecipe(id: String, in context: ModelContext) -> Recipe? {
        let descriptor = FetchDescriptor<Recipe>()
        guard let all = try? context.fetch(descriptor) else { return nil }
        return all.first { $0.catalogRecipeId == id }
    }

    @MainActor
    private static func cloneRecipe(
        _ source: Recipe,
        factor: Double,
        in context: ModelContext
    ) -> Recipe {
        let clone = Recipe(
            name: source.name,
            catalogRecipeId: source.catalogRecipeId,
            servings: 1,
            imageData: source.imageData,
            steps: source.steps,
            stepsRichTextData: source.stepsRichTextData,
            cookTimeMinutes: source.cookTimeMinutes,
            communityLikeCount: source.communityLikeCount,
            mealTypeTags: source.mealTypeTags,
            caloriesPer100g: source.caloriesPer100g,
            proteinPer100g: source.proteinPer100g,
            fatPer100g: source.fatPer100g,
            carbsPer100g: source.carbsPer100g
        )
        context.insert(clone)

        let ingredients = source.ingredients.map { ingredient in
            Ingredient(
                name: ingredient.name,
                quantity: ingredient.quantity * factor,
                unit: ingredient.unit,
                category: ingredient.category,
                recipe: clone,
                foodProduct: ingredient.foodProduct
            )
        }
        for ingredient in ingredients {
            context.insert(ingredient)
        }
        clone.ingredients = ingredients
        clone.recalculateNutrition()
        return clone
    }
}
