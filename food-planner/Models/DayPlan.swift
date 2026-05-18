import Foundation
import SwiftData

@Model
final class DayPlan {
    var date: Date

    @Relationship(deleteRule: .cascade, inverse: \Meal.dayPlan)
    var meals: [Meal]

    var weekPlan: WeekPlan?

    init(date: Date, meals: [Meal] = [], weekPlan: WeekPlan? = nil) {
        self.date = date
        self.meals = meals
        self.weekPlan = weekPlan
    }
}
