import Foundation

enum IngredientCategory: String, Codable, CaseIterable {
    case vegetables
    case meat
    case fish
    case dairy
    case grains
    case fruits
    case spices
    case other
}

extension IngredientCategory {
    var displayName: String {
        switch self {
        case .vegetables: "Овощи"
        case .meat: "Мясо"
        case .fish: "Рыба и морепродукты"
        case .dairy: "Молочные продукты"
        case .grains: "Крупы и макароны"
        case .fruits: "Фрукты"
        case .spices: "Специи и приправы"
        case .other: "Прочее"
        }
    }
}
