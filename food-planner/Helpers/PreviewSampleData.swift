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
        RecipeCatalogStore.seedIfNeeded(in: context)
        _ = AppSettingsService.settings(in: context)

        guard let breakfastRecipe = catalogRecipe(id: "recipe_01", in: context),
              let lunchRecipe = catalogRecipe(id: "recipe_10", in: context),
              let dinnerRecipe = catalogRecipe(id: "recipe_18", in: context) else {
            return
        }

        let weekPlan = WeekPlan(weekStartDate: Calendar.current.startOfWeek(for: .now))
        context.insert(weekPlan)

        let today = Calendar.current.startOfDay(for: .now)
        let dayPlan = DayPlan(date: today, weekPlan: weekPlan)
        context.insert(dayPlan)

        let breakfast = Meal(mealType: .breakfast, date: today, recipe: breakfastRecipe, dayPlan: dayPlan)
        let lunch = Meal(mealType: .lunch, date: today, recipe: lunchRecipe, dayPlan: dayPlan)
        let dinner = Meal(mealType: .dinner, date: today, recipe: dinnerRecipe, dayPlan: dayPlan)

        context.insert(breakfast)
        context.insert(lunch)
        context.insert(dinner)

        dayPlan.meals = [breakfast, lunch, dinner]
        weekPlan.dayPlans = [dayPlan]

        WeekPlanService.syncShoppingItems(for: weekPlan, in: context)
        AppSettingsService.setActiveWeekPlan(weekPlan, in: context)
        LocalPersistence.save(context)
    }

    @MainActor
    private static func catalogRecipe(id: String, in context: ModelContext) -> Recipe? {
        let descriptor = FetchDescriptor<Recipe>()
        guard let all = try? context.fetch(descriptor) else { return nil }
        return all.first { $0.catalogRecipeId == id }
    }
}
