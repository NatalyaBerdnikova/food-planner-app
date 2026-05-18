import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe

    private var displayCaloriesPer100g: Double {
        let nutrition = NutritionCalculator.recipeNutrition(recipe)
        return nutrition.totalWeightGrams > 0
            ? nutrition.per100g.calories
            : recipe.caloriesPer100g
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RecipeImageView(imageData: recipe.imageData)
                .frame(height: 100)
                .clipped()

            Text(recipe.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text(L10n.kcalPer100g(Int(displayCaloriesPer100g)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
