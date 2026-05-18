import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

extension MealType {
    var displayName: String {
        switch self {
        case .breakfast: "Завтрак"
        case .lunch: "Обед"
        case .dinner: "Ужин"
        case .snack: "Перекус"
        }
    }
}
