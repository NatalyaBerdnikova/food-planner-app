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

        guard let oatmeal = catalogRecipe(id: "oatmeal_berries", in: context),
              let soup = catalogRecipe(id: "chicken_soup", in: context),
              let salad = catalogRecipe(id: "greek_salad", in: context) else {
            return
        }

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

    @MainActor
    private static func catalogRecipe(id: String, in context: ModelContext) -> Recipe? {
        let descriptor = FetchDescriptor<Recipe>()
        guard let all = try? context.fetch(descriptor) else { return nil }
        return all.first { $0.catalogRecipeId == id }
    }
}
