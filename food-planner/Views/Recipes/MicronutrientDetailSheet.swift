import SwiftUI

struct MicronutrientDetailSheet: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    private var nutrition: RecipeNutrition {
        NutritionCalculator.recipeNutrition(recipe)
    }

    var body: some View {
        NavigationStack {
            List {
                if nutrition.totalWeightGrams > 0 {
                    Section("nutrition.section.total") {
                        nutrientRows(for: nutrition.total)
                    }

                    Section("nutrition.section.per100g") {
                        nutrientRows(for: nutrition.per100g)
                    }

                    Section {
                        Text(L10n.recipeWeight(Int(nutrition.totalWeightGrams.rounded())))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ContentUnavailableView(
                        "nutrition.noIngredients",
                        systemImage: "leaf",
                        description: Text("nutrition.noIngredients.hint")
                    )
                }
            }
            .navigationTitle("nutrition.microDetail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientRows(for totals: NutrientTotals) -> some View {
        macroRow("nutrition.macro.kcal", value: totals.calories, unit: "nutrition.unit.kcal")
        macroRow("nutrition.macro.protein", value: totals.protein, unit: "nutrition.unit.g")
        macroRow("nutrition.macro.fat", value: totals.fat, unit: "nutrition.unit.g")
        macroRow("nutrition.macro.carbs", value: totals.carbs, unit: "nutrition.unit.g")
        macroRow("micro.fiber", value: totals.fiber, unit: "nutrition.unit.g")
        macroRow("micro.sugar", value: totals.sugar, unit: "nutrition.unit.g")
        macroRow("micro.saturatedFat", value: totals.saturatedFat, unit: "nutrition.unit.g")
        macroRow("micro.sodium", value: totals.sodium, unit: "nutrition.unit.mg")
        macroRow("micro.potassium", value: totals.potassium, unit: "nutrition.unit.mg")
        macroRow("micro.calcium", value: totals.calcium, unit: "nutrition.unit.mg")
        macroRow("micro.iron", value: totals.iron, unit: "nutrition.unit.mg")
        macroRow("micro.magnesium", value: totals.magnesium, unit: "nutrition.unit.mg")
        macroRow("micro.zinc", value: totals.zinc, unit: "nutrition.unit.mg")
        macroRow("micro.vitaminC", value: totals.vitaminC, unit: "nutrition.unit.mg")
        macroRow("micro.vitaminD", value: totals.vitaminD, unit: "nutrition.unit.mcg")
        macroRow("micro.vitaminB12", value: totals.vitaminB12, unit: "nutrition.unit.mcg")
        macroRow("micro.folate", value: totals.folate, unit: "nutrition.unit.mcg")
    }

    private func macroRow(
        _ title: LocalizedStringResource,
        value: Double,
        unit: LocalizedStringResource
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(formatted(value)) \(String(localized: unit))")
                .foregroundStyle(.secondary)
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
