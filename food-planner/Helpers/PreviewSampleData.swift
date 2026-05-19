import Foundation
import SwiftData

enum PreviewSampleData {
    @MainActor
    static func populate(in container: ModelContainer) {
        let context = container.mainContext
        if let count = try? context.fetchCount(FetchDescriptor<Recipe>()), count > 0 {
            return
        }

        FoodCatalogSeeder.seedIfNeeded(in: context)
        _ = AppSettingsService.settings(in: context)

        func product(_ key: String) -> FoodProduct? {
            FoodCatalogSeeder.product(forKey: key, in: context)
        }

        func ingredient(
            key: String,
            quantity: Double,
            unit: MeasurementUnit,
            recipe: Recipe
        ) -> Ingredient? {
            guard let food = product(key) else { return nil }
            let name = food.displayName
            let ing = Ingredient(
                name: name,
                quantity: quantity,
                unit: unit,
                category: food.category,
                recipe: recipe,
                foodProduct: food
            )
            context.insert(ing)
            return ing
        }

        let oatmeal = Recipe(
            name: "Овсянка с ягодами",
            steps: ["Залить овсянку молоком", "Добавить ягоды"]
        )
        context.insert(oatmeal)
        if let o = ingredient(key: "oatmeal", quantity: 80, unit: .gram, recipe: oatmeal),
           let m = ingredient(key: "milk", quantity: 200, unit: .milliliter, recipe: oatmeal),
           let b = ingredient(key: "banana", quantity: 1, unit: .piece, recipe: oatmeal) {
            oatmeal.ingredients = [o, m, b]
        }
        oatmeal.recalculateNutrition()

        let soup = Recipe(name: "Куриный суп")
        context.insert(soup)
        if let c = ingredient(key: "chicken_breast", quantity: 300, unit: .gram, recipe: soup),
           let car = ingredient(key: "carrot", quantity: 1, unit: .piece, recipe: soup),
           let on = ingredient(key: "onion", quantity: 1, unit: .piece, recipe: soup) {
            soup.ingredients = [c, car, on]
        }
        soup.recalculateNutrition()

        let salad = Recipe(name: "Греческий салат")
        context.insert(salad)
        if let t = ingredient(key: "tomato", quantity: 2, unit: .piece, recipe: salad),
           let cu = ingredient(key: "cucumber", quantity: 1, unit: .piece, recipe: salad),
           let ch = ingredient(key: "cheese", quantity: 100, unit: .gram, recipe: salad),
           let oil = ingredient(key: "olive_oil", quantity: 1, unit: .tablespoon, recipe: salad) {
            salad.ingredients = [t, cu, ch, oil]
        }
        salad.recalculateNutrition()

        let weekPlan = WeekPlan(weekStartDate: Calendar.current.startOfWeek(for: .now))
        context.insert(weekPlan)

        let today = Calendar.current.startOfDay(for: .now)
        let dayPlan = DayPlan(date: today, weekPlan: weekPlan)
        context.insert(dayPlan)

        let breakfast = Meal(mealType: .breakfast, date: today, recipe: oatmeal, dayPlan: dayPlan)
        let lunch = Meal(mealType: .lunch, date: today, recipe: soup, dayPlan: dayPlan)
        let dinner = Meal(mealType: .dinner, date: today, recipe: salad, dayPlan: dayPlan)

        context.insert(breakfast)
        context.insert(lunch)
        context.insert(dinner)

        dayPlan.meals = [breakfast, lunch, dinner]
        weekPlan.dayPlans = [dayPlan]

        WeekPlanService.syncShoppingItems(for: weekPlan, in: context)
        AppSettingsService.setActiveWeekPlan(weekPlan, in: context)
        LocalPersistence.save(context)
    }
}
