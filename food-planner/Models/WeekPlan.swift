import Foundation
import SwiftData

@Model
final class WeekPlan {
    var weekStartDate: Date

    @Relationship(deleteRule: .cascade, inverse: \DayPlan.weekPlan)
    var dayPlans: [DayPlan]

    @Relationship(deleteRule: .cascade, inverse: \ShoppingItem.weekPlan)
    var shoppingItems: [ShoppingItem]

    init(
        weekStartDate: Date,
        dayPlans: [DayPlan] = [],
        shoppingItems: [ShoppingItem] = []
    ) {
        self.weekStartDate = weekStartDate
        self.dayPlans = dayPlans
        self.shoppingItems = shoppingItems
    }

    /// Сводный список покупок из ингредиентов всех приёмов пищи недели.
    /// На каждый слот плана берётся 1 порция рецепта; одинаковые продукты суммируются.
    var aggregatedShoppingList: [AggregatedShoppingItem] {
        var totals: [String: (name: String, quantity: Double, unit: MeasurementUnit, category: IngredientCategory)] = [:]

        for dayPlan in dayPlans {
            for meal in dayPlan.meals {
                guard let recipe = meal.recipe else { continue }
                let servings = max(Double(recipe.servings), 1)

                for ingredient in recipe.ingredients {
                    let portionQuantity = ingredient.quantity / servings
                    let catalogKey = ingredient.foodProduct?.catalogKey ?? ingredient.name
                    let key = "\(catalogKey.lowercased())|\(ingredient.unit.rawValue)"

                    if let existing = totals[key] {
                        totals[key] = (
                            existing.name,
                            existing.quantity + portionQuantity,
                            existing.unit,
                            existing.category
                        )
                    } else {
                        totals[key] = (
                            catalogKey,
                            portionQuantity,
                            ingredient.unit,
                            ingredient.category
                        )
                    }
                }
            }
        }

        return totals
            .map { key, value in
                AggregatedShoppingItem(
                    id: key,
                    name: value.name,
                    quantity: value.quantity,
                    unit: value.unit,
                    category: value.category
                )
            }
            .sorted { lhs, rhs in
                if lhs.category.rawValue != rhs.category.rawValue {
                    return lhs.category.rawValue < rhs.category.rawValue
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }
}
