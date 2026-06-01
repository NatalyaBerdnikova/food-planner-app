import Foundation

enum RecipeFilterTab: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var mealType: MealType {
        MealType(rawValue: rawValue) ?? .breakfast
    }

    var displayName: LocalizedStringResource {
        switch self {
        case .breakfast: "mealType.breakfast"
        case .lunch: "mealType.lunch"
        case .dinner: "mealType.dinner"
        case .snack: "filter.other"
        }
    }
}
