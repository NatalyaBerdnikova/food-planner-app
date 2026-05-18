import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    @State private var showMicronutrients = false

    private var nutrition: RecipeNutrition {
        NutritionCalculator.recipeNutrition(recipe)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RecipeImageView(imageData: recipe.imageData, cornerRadius: 16)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                Text(recipe.name)
                    .font(.title.bold())

                if nutrition.totalWeightGrams > 0 {
                    NutritionSummaryView(
                        nutrition: nutrition.per100g.macros,
                        title: "nutrition.title.per100g"
                    )

                    HStack {
                        Text(L10n.recipeTotalCalories(Int(nutrition.total.calories.rounded())))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(L10n.recipeWeight(Int(nutrition.totalWeightGrams.rounded())))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showMicronutrients = true
                    } label: {
                        Label("nutrition.microDetail", systemImage: "chart.bar.doc.horizontal")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    NutritionSummaryView(
                        nutrition: DailyNutrition(
                            calories: recipe.caloriesPer100g,
                            protein: recipe.proteinPer100g,
                            fat: recipe.fatPer100g,
                            carbs: recipe.carbsPer100g
                        ),
                        title: "nutrition.title.per100g"
                    )
                }

                if !recipe.ingredients.isEmpty {
                    sectionTitle("recipe.ingredients")
                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let product = ingredient.foodProduct {
                                    Text(LocalizedStringResource(stringLiteral: product.localizationKey))
                                } else {
                                    Text(ingredient.name)
                                }
                                Text(L10n.amount(quantity: ingredient.quantity, unit: ingredient.unit))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if ingredient.foodProduct != nil {
                                Text(L10n.kcalShort(Int(NutritionCalculator.ingredientNutrition(ingredient).calories.rounded())))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                }

                if !recipe.steps.isEmpty {
                    sectionTitle("recipe.steps")
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
                    Link("recipe.source", destination: url)
                        .font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMicronutrients) {
            MicronutrientDetailSheet(recipe: recipe)
        }
        .onAppear {
            recipe.recalculateNutrition()
        }
    }

    private func sectionTitle(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(.headline)
    }
}
