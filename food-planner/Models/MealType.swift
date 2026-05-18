import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

extension MealType {
    var displayName: LocalizedStringResource {
        switch self {
        case .breakfast: "mealType.breakfast"
        case .lunch: "mealType.lunch"
        case .dinner: "mealType.dinner"
        case .snack: "mealType.snack"
        }
    }
}
