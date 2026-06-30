import Foundation
import SwiftData

extension DayPlan {
    func meals(for mealType: MealType) -> [Meal] {
        meals
            .filter { $0.mealType == mealType }
            .sorted { lhs, rhs in
                (lhs.recipe?.localizedName ?? "").localizedCaseInsensitiveCompare(rhs.recipe?.localizedName ?? "") == .orderedAscending
            }
    }
}
