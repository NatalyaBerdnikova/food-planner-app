import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let recipe: Recipe

    @State private var showMicronutrients = false
    @State private var showUnfavoriteConfirmation = false
    @State private var displayPortions = 1

    private var nutrition: RecipeNutrition {
        NutritionCalculator.recipeNutrition(recipe)
    }

    private var nutritionPerServing: DailyNutrition {
        NutritionCalculator.nutritionPerServing(for: recipe)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RecipeImageView(imageData: recipe.imageData, cornerRadius: 16)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                Text(recipe.name)
                    .font(.title.bold())

                portionsControl

                if nutrition.totalWeightGrams > 0 {
                    NutritionSummaryView(
                        nutrition: nutritionPerServing,
                        title: "nutrition.title.perServing"
                    )

                    HStack {
                        Text(L10n.recipeCaloriesPerServing(Int(nutritionPerServing.calories.rounded())))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(L10n.recipeWeightPerServing(Int(NutritionCalculator.weightPerServingGrams(for: recipe).rounded())))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showMicronutrients = true
                    } label: {
                        Label("recipe.moreDetails", systemImage: "list.bullet.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    NutritionSummaryView(
                        nutrition: nutritionPerServing,
                        title: "nutrition.title.perServing"
                    )
                }

                if !recipe.ingredients.isEmpty {
                    sectionTitle("recipe.ingredients")
                    ForEach(recipe.ingredients) { ingredient in
                        ingredientRow(ingredient)
                    }
                }

                if hasSteps {
                    sectionTitle("recipe.steps")
                    recipeStepsContent
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
        .toolbar {
            if recipe.isCatalogRecipe {
                ToolbarItem(placement: .topBarTrailing) {
                    favoriteToolbarButton
                }
            }
        }
        .alert("favorites.remove.title", isPresented: $showUnfavoriteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("favorites.remove.confirm", role: .destructive) {
                RecipeFavoritesService.setFavorite(recipe, favorite: false, in: modelContext)
            }
        } message: {
            Text("favorites.remove.message \(recipe.name)")
        }
        .sheet(isPresented: $showMicronutrients) {
            MicronutrientDetailSheet(recipe: recipe)
        }
        .onAppear {
            recipe.recalculateNutrition()
            LocalPersistence.save(modelContext)
        }
    }

    private var portionsControl: some View {
        Stepper(value: $displayPortions, in: 1...99) {
            Text("recipe.displayPortions \(displayPortions)")
        }
        .font(.subheadline)
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        let quantity = NutritionCalculator.displayQuantity(
            for: ingredient,
            displayPortions: Double(displayPortions),
            recipeServings: recipe.servings
        )
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.displayName)
                Text(L10n.amount(quantity: quantity, unit: ingredient.unit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let product = ingredient.foodProduct {
                let grams = UnitConverter.grams(
                    quantity: quantity,
                    unit: ingredient.unit,
                    product: product
                )
                let kcal = product.nutrientsPer100g.calories * grams / 100
                Text(L10n.kcalShort(Int(kcal.rounded())))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    private var isFavorite: Bool {
        RecipeFavoritesService.isFavorite(recipe, in: modelContext)
    }

    @ViewBuilder
    private var favoriteToolbarButton: some View {
        Button {
            if isFavorite {
                showUnfavoriteConfirmation = true
            } else {
                RecipeFavoritesService.setFavorite(recipe, favorite: true, in: modelContext)
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? .red : .primary)
        }
        .accessibilityLabel(
            isFavorite
                ? String(localized: "accessibility.removeFavorite")
                : String(localized: "accessibility.addFavorite")
        )
    }

    private var hasSteps: Bool {
        recipe.stepsRichTextData != nil || !recipe.steps.isEmpty
    }

    @ViewBuilder
    private var recipeStepsContent: some View {
        if let data = recipe.stepsRichTextData,
           let attributed = RecipeStepsStorage.attributedString(from: data) {
            Text(AttributedString(attributed))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
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
    }

    private func sectionTitle(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(.headline)
    }
}
