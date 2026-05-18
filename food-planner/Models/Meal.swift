import Foundation
import SwiftData

@Model
final class Meal {
    var mealType: MealType
    var date: Date

    var recipe: Recipe?
    var dayPlan: DayPlan?

    init(
        mealType: MealType,
        date: Date,
        recipe: Recipe? = nil,
        dayPlan: DayPlan? = nil
    ) {
        self.mealType = mealType
        self.date = date
        self.recipe = recipe
        self.dayPlan = dayPlan
    }
}
