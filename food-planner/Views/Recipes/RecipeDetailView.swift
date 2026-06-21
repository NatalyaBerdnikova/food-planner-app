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
            VStack(alignment: .leading, spacing: 18) {
                heroSection

                if nutrition.totalWeightGrams > 0 {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(
                                title: "nutrition.title.perServing",
                                systemImage: "chart.bar.fill"
                            )

                            NutritionSummaryView(
                                nutrition: nutritionPerServing,
                                title: "nutrition.title.perServing",
                                embedded: true,
                                macroLabelStyle: .full
                            )

                            HStack(spacing: 10) {
                                detailMetricChip(
                                    icon: "flame.fill",
                                    title: "recipeDetail.energy",
                                    value: L10n.recipeCaloriesPerServing(Int(nutritionPerServing.calories.rounded()))
                                )
                                detailMetricChip(
                                    icon: "scalemass.fill",
                                    title: "recipeDetail.portionWeight",
                                    value: L10n.recipeWeightPerServing(Int(weightPerServing.rounded()))
                                )
                            }

                            Button {
                                showMicronutrients = true
                            } label: {
                                Label("recipe.moreDetails", systemImage: "list.bullet.rectangle")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.06, green: 0.33, blue: 0.45))
                        }
                    }
                } else {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(
                                title: "nutrition.title.perServing",
                                systemImage: "chart.bar.fill"
                            )

                            NutritionSummaryView(
                                nutrition: nutritionPerServing,
                                title: "nutrition.title.perServing",
                                embedded: true,
                                macroLabelStyle: .full
                            )
                        }
                    }
                }

                if !recipe.ingredients.isEmpty {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(
                                title: "recipe.ingredients",
                                systemImage: "leaf.fill",
                                subtitle: "\(recipe.ingredients.count)"
                            )
                            VStack(spacing: 10) {
                                ForEach(recipe.ingredients) { ingredient in
                                    ingredientRow(ingredient)
                                }
                            }
                        }
                    }
                }

                if hasSteps {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader(title: "recipe.steps", systemImage: "list.number")
                            recipeStepsContent
                        }
                    }
                }

                if let urlString = recipe.sourceURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("recipe.source", systemImage: "safari.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RecipeImageView(imageData: recipe.imageData, cornerRadius: 26)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .overlay {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.18), .black.opacity(0.74)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }

            VStack(alignment: .leading, spacing: 14) {
                Text(recipe.name)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .shadow(color: .black.opacity(0.28), radius: 8, y: 4)

                HStack(spacing: 8) {
                    heroMetricChip(
                        icon: "person.2.fill",
                        text: String(localized: "recipeDetail.servings \(recipe.servings)")
                    )
                    heroMetricChip(
                        icon: "carrot.fill",
                        text: String(localized: "recipeDetail.ingredients \(recipe.ingredients.count)")
                    )
                    if nutrition.totalWeightGrams > 0 {
                        heroMetricChip(
                            icon: "scalemass.fill",
                            text: L10n.recipeWeight(Int(nutrition.totalWeightGrams.rounded()))
                        )
                    }
                }

                portionsControl
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 22, x: 0, y: 12)
    }

    private var portionsControl: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("recipeDetail.calculateFor")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                Text("recipe.displayPortions \(displayPortions)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Stepper("", value: $displayPortions, in: 1...99)
                .labelsHidden()
                .tint(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .colorScheme(.dark)
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        let quantity = NutritionCalculator.displayQuantity(
            for: ingredient,
            displayPortions: Double(displayPortions),
            recipeServings: recipe.servings
        )
        return HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color(red: 0.18, green: 0.54, blue: 0.36))
                .frame(width: 24, height: 24)
                .background(Color(red: 0.18, green: 0.54, blue: 0.36).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.06, green: 0.33, blue: 0.45))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.06, green: 0.33, blue: 0.45).opacity(0.1), in: Capsule())
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color(red: 0.06, green: 0.33, blue: 0.45), in: Circle())
                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var weightPerServing: Double {
        NutritionCalculator.weightPerServingGrams(for: recipe)
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            }
    }

    private func sectionHeader(
        title: LocalizedStringResource,
        systemImage: String,
        subtitle: String? = nil
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(red: 0.06, green: 0.33, blue: 0.45))
                .frame(width: 30, height: 30)
                .background(Color(red: 0.06, green: 0.33, blue: 0.45).opacity(0.1), in: Circle())
            Text(title)
                .font(.headline)
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }
        }
    }

    private func heroMetricChip(icon: String, text: String) -> some View {
        Label {
            Text(text)
                .lineLimit(1)
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.black.opacity(0.24), in: Capsule())
    }

    private func detailMetricChip(
        icon: String,
        title: LocalizedStringResource,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
            }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
