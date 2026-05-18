import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RecipeImageView(imageData: recipe.imageData)
                .frame(height: 100)
                .clipped()

            Text(recipe.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text("\(Int(recipe.caloriesPer100g)) ккал / 100 г")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
