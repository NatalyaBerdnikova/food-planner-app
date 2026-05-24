import Foundation

enum RecipeFilterTab: String, CaseIterable, Identifiable {
    case all
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var mealType: MealType? {
        MealType(rawValue: rawValue)
    }

    var displayName: LocalizedStringResource {
        switch self {
        case .all: "filter.all"
        case .breakfast: "mealType.breakfast"
        case .lunch: "mealType.lunch"
        case .dinner: "mealType.dinner"
        case .snack: "filter.other"
        }
    }
}
