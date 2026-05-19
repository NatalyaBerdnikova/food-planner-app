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

    init(
        singletonKey: String = "main",
        targetCalories: Double = 2000,
        targetProtein: Double = 90,
        targetFat: Double = 70,
        targetCarbs: Double = 250,
        activeWeekPlan: WeekPlan? = nil
    ) {
        self.singletonKey = singletonKey
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetFat = targetFat
        self.targetCarbs = targetCarbs
        self.activeWeekPlan = activeWeekPlan
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
