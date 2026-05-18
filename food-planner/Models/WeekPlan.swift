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

    /// Сводный список покупок из ингредиентов всех рецептов недели.
    /// Одинаковые продукты (название + единица) суммируются.
    var aggregatedShoppingList: [AggregatedShoppingItem] {
        var totals: [String: (name: String, quantity: Double, unit: MeasurementUnit, category: IngredientCategory)] = [:]

        for dayPlan in dayPlans {
            for meal in dayPlan.meals {
                guard let recipe = meal.recipe else { continue }

                for ingredient in recipe.ingredients {
                    let key = "\(ingredient.name.lowercased())|\(ingredient.unit.rawValue)"

                    if let existing = totals[key] {
                        totals[key] = (
                            existing.name,
                            existing.quantity + ingredient.quantity,
                            existing.unit,
                            existing.category
                        )
                    } else {
                        totals[key] = (
                            ingredient.name,
                            ingredient.quantity,
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
                if lhs.category.displayName != rhs.category.displayName {
                    return lhs.category.displayName < rhs.category.displayName
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }
}
