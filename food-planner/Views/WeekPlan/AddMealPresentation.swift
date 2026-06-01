import SwiftData
import SwiftUI

struct AddMealPresentation: Identifiable {
    let dayPlan: DayPlan
    let mealType: MealType

    var id: String {
        "\(dayPlan.persistentModelID)-\(mealType.rawValue)"
    }
}
