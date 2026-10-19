import SwiftUI
import SwiftData

struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @Binding var selectedRecipe: Recipe?

    private var visibleRecipes: [Recipe] {
        RecipeCollections.visible(recipes)
    }

    var body: some View {
        List(visibleRecipes) { recipe in
            Button {
                selectedRecipe = recipe
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    RecipeImageView(imageData: recipe.imageData, cornerRadius: 8)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.localizedName)
                            .foregroundStyle(.primary)
                        Text(L10n.kcalPer100g(Int(recipe.caloriesPer100g)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if selectedRecipe?.persistentModelID == recipe.persistentModelID {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("nav.recipePicker")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if recipes.isEmpty {
                ContentUnavailableView(
                    "empty.recipes",
                    systemImage: "book.closed",
                    description: Text("empty.recipes.hint")
                )
            }
        }
    }
}
