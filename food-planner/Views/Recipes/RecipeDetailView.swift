import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RecipeImageView(imageData: recipe.imageData, cornerRadius: 16)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                Text(recipe.name)
                    .font(.title.bold())

                NutritionSummaryView(
                    nutrition: DailyNutrition(
                        calories: recipe.caloriesPer100g,
                        protein: recipe.proteinPer100g,
                        fat: recipe.fatPer100g,
                        carbs: recipe.carbsPer100g
                    ),
                    title: "КБЖУ на 100 г"
                )

                if !recipe.ingredients.isEmpty {
                    sectionTitle("Ингредиенты")
                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Text("\(formatted(ingredient.quantity)) \(ingredient.unit.displayName)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }

                if !recipe.steps.isEmpty {
                    sectionTitle("Шаги")
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tint)
                            Text(step)
                        }
                        .font(.subheadline)
                    }
                }

                if let urlString = recipe.sourceURL, let url = URL(string: urlString) {
                    Link("Источник", destination: url)
                        .font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
