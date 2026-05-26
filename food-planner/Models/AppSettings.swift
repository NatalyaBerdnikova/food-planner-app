import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var singletonKey: String

    var targetCalories: Double
    var targetProtein: Double
    var targetFat: Double
    var targetCarbs: Double

    var activeWeekPlan: WeekPlan?

    /// `catalogRecipeId` рецептов из каталога, добавленных в «Мои рецепты».
    var favoriteCatalogRecipeIds: [String]

    init(
        singletonKey: String = "main",
        targetCalories: Double = 2000,
        targetProtein: Double = 90,
        targetFat: Double = 70,
        targetCarbs: Double = 250,
        activeWeekPlan: WeekPlan? = nil,
        favoriteCatalogRecipeIds: [String] = []
    ) {
        self.singletonKey = singletonKey
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetFat = targetFat
        self.targetCarbs = targetCarbs
        self.activeWeekPlan = activeWeekPlan
        self.favoriteCatalogRecipeIds = favoriteCatalogRecipeIds
    }

    var targetNutrition: DailyNutrition {
        DailyNutrition(
            calories: targetCalories,
            protein: targetProtein,
            fat: targetFat,
            carbs: targetCarbs
        )
    }
}
