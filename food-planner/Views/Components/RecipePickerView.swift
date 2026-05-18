import SwiftUI
import SwiftData

struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @Binding var selectedRecipe: Recipe?

    var body: some View {
        List(recipes) { recipe in
            Button {
                selectedRecipe = recipe
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    RecipeImageView(imageData: recipe.imageData, cornerRadius: 8)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.name)
                            .foregroundStyle(.primary)
                        Text("\(Int(recipe.caloriesPer100g)) ккал / 100 г")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if selectedRecipe?.persistentModelID == recipe.persistentModelID {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        .navigationTitle("Выбор рецепта")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if recipes.isEmpty {
                ContentUnavailableView(
                    "Нет рецептов",
                    systemImage: "book.closed",
                    description: Text("Добавьте рецепт во вкладке «Рецепты»")
                )
            }
        }
    }
}
