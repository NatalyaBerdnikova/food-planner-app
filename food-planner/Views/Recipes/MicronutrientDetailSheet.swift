import SwiftUI

struct MicronutrientDetailSheet: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    private var nutrition: RecipeNutrition {
        NutritionCalculator.recipeNutrition(recipe)
    }

    private var perServing: NutrientTotals {
        let servings = max(Double(recipe.servings), 1)
        return nutrition.total.scaled(by: 1 / servings)
    }

    var body: some View {
        NavigationStack {
            List {
                if nutrition.totalWeightGrams > 0 {
                    Section {
                        ForEach(MicronutrientKind.allCases) { kind in
                            MicronutrientProgressRow(
                                kind: kind,
                                actual: perServing.value(for: kind)
                            )
                        }
                    } footer: {
                        Text("nutrition.microDailyReference")
                    }
                } else {
                    ContentUnavailableView(
                        "nutrition.noIngredients",
                        systemImage: "leaf",
                        description: Text("nutrition.noIngredients.hint")
                    )
                }
            }
            .navigationTitle("nutrition.microTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }
}
