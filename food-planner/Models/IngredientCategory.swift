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
    /// Порядок в рецепте и списке покупок: белок и основа → гарнир → мелочь и специи.
    static let recipeDisplayOrder: [IngredientCategory] = [
        .meat,
        .fish,
        .dairy,
        .grains,
        .vegetables,
        .greens,
        .fruits,
        .nuts,
        .seeds,
        .spices,
        .other,
    ]

    var recipeDisplayOrderIndex: Int {
        Self.recipeDisplayOrder.firstIndex(of: self) ?? Int.max
    }

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
