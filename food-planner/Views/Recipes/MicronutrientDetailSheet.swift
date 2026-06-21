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
                    micronutrientRows(for: perServing)
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

    @ViewBuilder
    private func micronutrientRows(for totals: NutrientTotals) -> some View {
        ForEach(MicronutrientKind.allCases) { kind in
            HStack {
                Text(kind.displayName)
                Spacer()
                Text("\(formatted(totals.value(for: kind))) \(String(localized: String.LocalizationValue(kind.unitLocalizationKey)))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
