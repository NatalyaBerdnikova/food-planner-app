import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    var isPreviewPresentation: Bool = false

    @State private var showMicronutrients = false
    @State private var showDeleteConfirmation = false
    @State private var showHideConfirmation = false
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

                sectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        nutritionSectionHeader

                        NutritionSummaryView(
                            nutrition: nutritionPerServing,
                            title: "nutrition.title.perServing",
                            embedded: true,
                            macroLabelStyle: .full
                        )
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

                            HStack(spacing: 12) {
                                Text("recipeDetail.calculateFor")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 0)
                                Text("recipe.displayPortions \(displayPortions)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Stepper("", value: $displayPortions, in: 1...99)
                                    .labelsHidden()
                            }

                            VStack(spacing: 10) {
                                ForEach(recipe.ingredients) { ingredient in
                                    ingredientRow(ingredient)
                                }
                            }
                        }
                    }
                }

                if recipe.hasLocalizedSteps {
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

                if !isPreviewPresentation {
                    recipeLifecycleButton
                }
            }
            .padding()
            .appReadableWidth()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(recipe.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isPreviewPresentation, RecipeFavoritesService.canFavorite(recipe) {
                ToolbarItem(placement: .topBarTrailing) {
                    favoriteToolbarButton
                }
            }
        }
        .alert("recipeDetail.delete.title", isPresented: $showDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("recipeDetail.delete.confirm", role: .destructive) {
                removeRecipeFromDevice(hidingCatalog: false)
            }
        } message: {
            Text("recipeDetail.delete.message \(recipe.localizedName)")
        }
        .alert("recipeDetail.hide.title", isPresented: $showHideConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("recipeDetail.hide.confirm", role: .destructive) {
                removeRecipeFromDevice(hidingCatalog: true)
            }
        } message: {
            Text("recipeDetail.hide.message \(recipe.localizedName)")
        }
        .sheet(isPresented: $showMicronutrients) {
            MicronutrientDetailSheet(
                recipe: recipe,
                micronutrientFocus: AppSettingsService.settings(in: modelContext).profileMicronutrientFocus
            )
        }
        .onAppear {
            displayPortions = max(recipe.servings, 1)
            recipe.recalculateNutrition()
            LocalPersistence.save(modelContext)
        }
    }

    private var recipeLifecycleButton: some View {
        Button(role: .destructive) {
            if recipe.isUserCreated {
                showDeleteConfirmation = true
            } else {
                showHideConfirmation = true
            }
        } label: {
            Label {
                Text(recipe.isUserCreated ? "recipeDetail.delete" : "recipeDetail.hide")
            } icon: {
                Image(systemName: recipe.isUserCreated ? "trash" : "eye.slash")
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
    }

    private func removeRecipeFromDevice(hidingCatalog: Bool) {
        let context = modelContext
        let recipeToRemove = recipe
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            if hidingCatalog {
                RecipeVisibilityService.hideCatalogRecipe(recipeToRemove, in: context)
            } else {
                RecipeVisibilityService.deleteUserRecipe(recipeToRemove, in: context)
            }
        }
    }

    private var heroSection: some View {
        ZStack {
            RecipeImageView(imageData: recipe.imageData, cornerRadius: 0)
                .overlay {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.12), .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    if recipe.hasCookTime {
                        heroMetricChip(
                            icon: "clock.fill",
                            text: String(localized: "recipe.cookTime \(recipe.cookTimeMinutes)")
                        )
                    }

                    Spacer(minLength: 0)

                    if recipe.isUserCreated {
                        heroMetricChip(
                            icon: "person.fill",
                            text: String(localized: "recipeDetail.yours")
                        )
                    } else {
                        heroMetricChip(
                            icon: "heart.fill",
                            text: "\(displayedCommunityLikeCount)"
                        )
                    }
                }

                Spacer(minLength: 0)

                personalRatingControl
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 22, x: 0, y: 12)
    }

    private var displayedCommunityLikeCount: Int {
        guard isPreviewPresentation else { return recipe.communityLikeCount }
        var hasher = Hasher()
        hasher.combine(recipe.catalogRecipeId ?? recipe.name)
        let seed = abs(hasher.finalize())
        return 36 + (seed % 420)
    }

    private var personalRatingControl: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("recipeDetail.yourRating")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("recipeDetail.yourRating.caption")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            RecipeUserRatingView(
                rating: isPreviewPresentation ? 0 : recipe.userRating,
                isInteractive: !isPreviewPresentation,
                starSize: .title3
            ) { value in
                guard !isPreviewPresentation else { return }
                recipe.setUserRating(value)
                LocalPersistence.save(modelContext)
            }
            .fixedSize(horizontal: true, vertical: false)
            .allowsHitTesting(!isPreviewPresentation)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.contentOverlayFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24, height: 24)
                .background(AppTheme.accent.opacity(0.12), in: Circle())

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
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.1), in: Capsule())
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
            RecipeFavoritesService.setFavorite(recipe, favorite: !isFavorite, in: modelContext)
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

    @ViewBuilder
    private var recipeStepsContent: some View {
        if let attributed = recipe.localizedStepsAttributed {
            RecipeStepsTextView(attributedText: attributed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var weightPerServing: Double {
        NutritionCalculator.weightPerServingGrams(for: recipe)
    }

    private var nutritionSectionHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.1), in: Circle())

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("nutrition.title.perServing")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if weightPerServing > 0 {
                    Text("nutrition.servingGrams \(Int(weightPerServing.rounded()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            Button {
                showMicronutrients = true
            } label: {
                Text("recipe.micronutrients")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("recipe.micronutrients")
        }
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
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.1), in: Circle())
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
