import Foundation
import SwiftData

enum PreviewSampleData {
    @MainActor
    static func populate(in container: ModelContainer) {
        let context = container.mainContext
        if let count = try? context.fetchCount(FetchDescriptor<Recipe>()), count > 0 {
            return
        }

        let oatmeal = Recipe(
            name: "Овсянка с ягодами",
            steps: ["Залить овсянку молоком", "Добавить ягоды"],
            caloriesPer100g: 350,
            proteinPer100g: 12,
            fatPer100g: 8,
            carbsPer100g: 55,
            ingredients: [
                Ingredient(name: "Овсянка", quantity: 80, unit: .gram, category: .grains),
                Ingredient(name: "Молоко", quantity: 200, unit: .milliliter, category: .dairy),
            ]
        )

        let soup = Recipe(
            name: "Куриный суп",
            caloriesPer100g: 45,
            proteinPer100g: 4,
            fatPer100g: 1.5,
            carbsPer100g: 5,
            ingredients: [
                Ingredient(name: "Курица", quantity: 300, unit: .gram, category: .meat),
                Ingredient(name: "Морковь", quantity: 1, unit: .piece, category: .vegetables),
            ]
        )

        let salad = Recipe(
            name: "Греческий салат",
            caloriesPer100g: 120,
            proteinPer100g: 4,
            fatPer100g: 9,
            carbsPer100g: 6,
            ingredients: [
                Ingredient(name: "Помидоры", quantity: 2, unit: .piece, category: .vegetables),
                Ingredient(name: "Сыр фета", quantity: 100, unit: .gram, category: .dairy),
            ]
        )

        context.insert(oatmeal)
        context.insert(soup)
        context.insert(salad)

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
    }
}
