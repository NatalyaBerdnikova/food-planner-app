import Foundation

enum IngredientCategory: String, Codable, CaseIterable {
    case vegetables
    case greens
    case meat
    case fish
    case dairy
    case grains
    case fruits
    case nuts
    case seeds
    case spices
    case other
}

extension IngredientCategory {
    /// Порядок секций в списке покупок.
    static let shoppingListOrder: [IngredientCategory] = [
        .vegetables,
        .greens,
        .fruits,
        .nuts,
        .seeds,
        .meat,
        .fish,
        .dairy,
        .grains,
        .spices,
        .other,
    ]

    var displayName: LocalizedStringResource {
        switch self {
        case .vegetables: "category.vegetables"
        case .greens: "category.greens"
        case .meat: "category.meat"
        case .fish: "category.fish"
        case .dairy: "category.dairy"
        case .grains: "category.grains"
        case .fruits: "category.fruits"
        case .nuts: "category.nuts"
        case .seeds: "category.seeds"
        case .spices: "category.spices"
        case .other: "category.other"
        }
    }
}
