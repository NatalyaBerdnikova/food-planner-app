import SwiftUI
import SwiftData

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    let dayPlan: DayPlan
    let targetMealType: MealType
    let onSave: () -> Void

    @State private var filterTab: RecipeFilterTab = .all
    @State private var showFavoritesOnly = false
    @State private var showMineOnly = false
    @State private var selectedRecipeIDs: Set<PersistentIdentifier>
    @State private var pinnedSelectedIDs: Set<PersistentIdentifier>
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    init(
        dayPlan: DayPlan,
        preferredMealType: MealType = .breakfast,
        onSave: @escaping () -> Void
    ) {
        self.dayPlan = dayPlan
        self.targetMealType = preferredMealType
        self.onSave = onSave

        let existingIDs = Set(
            dayPlan.meals(for: preferredMealType).compactMap(\.recipe?.persistentModelID)
        )
        _selectedRecipeIDs = State(initialValue: existingIDs)
        _pinnedSelectedIDs = State(initialValue: existingIDs)
    }

    private var navigationTitle: LocalizedStringResource {
        targetMealType == .snack ? "filter.other" : targetMealType.displayName
    }

    private var emptyStateHint: String {
        let hasFilters = !searchText.isEmpty || showFavoritesOnly || showMineOnly || filterTab != .all
        return hasFilters
            ? String(localized: "search.noResults.hint")
            : String(localized: "empty.recipes.hint")
    }

    private var favoriteIds: Set<String> {
        RecipeFavoritesService.favoriteIds(in: modelContext)
    }

    private var filteredRecipes: [Recipe] {
        var result = RecipeCollections.visible(recipes)

        if showMineOnly {
            result = result.filter(\.isUserCreated)
        }

        if showFavoritesOnly {
            result = RecipeFavoritesService.favoriteRecipes(from: result, favoriteIds: favoriteIds)
        }

        if let filterMealType = filterTab.mealType {
            result = result.filter { $0.matchesMealTypeFilter(filterMealType) }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter { $0.matchesSearch(query) }
        }

        return result
    }

    private var displayedRecipes: [Recipe] {
        let base = filteredRecipes
        let pinned = base.filter { pinnedSelectedIDs.contains($0.persistentModelID) }
        let rest = base.filter { !pinnedSelectedIDs.contains($0.persistentModelID) }
        return pinned + rest
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if displayedRecipes.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "empty.recipes" : "search.noResults",
                        systemImage: "magnifyingglass",
                        description: Text(emptyStateHint)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayedRecipes) { recipe in
                            selectableRecipeCard(recipe)
                        }
                    }
                    .padding(AppTheme.contentPadding)
                    .padding(.bottom, selectedRecipeIDs.isEmpty ? 0 : 56)
                }
            }
            .background(AppTheme.canvas)
            .overlay(alignment: .bottomLeading) {
                selectedCountTag
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                pinnedFilterChips
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "search.recipes"
            )
            .toolbar { toolbarContent }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var pinnedFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecipeFilterTab.allCases) { tab in
                    filterChip(
                        title: tab.displayName,
                        isSelected: filterTab == tab
                    ) {
                        filterTab = tab
                    }
                }

                filterChip(
                    title: "filter.mine",
                    isSelected: showMineOnly,
                    systemImage: "person.fill"
                ) {
                    showMineOnly.toggle()
                }

                filterChip(
                    title: "filter.favorites",
                    isSelected: showFavoritesOnly,
                    systemImage: "heart.fill"
                ) {
                    showFavoritesOnly.toggle()
                }
            }
            .padding(.horizontal, AppTheme.contentPadding)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevated)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    @ViewBuilder
    private var selectedCountTag: some View {
        if !selectedRecipeIDs.isEmpty {
            Text("addMeal.selectedCount \(selectedRecipeIDs.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
                .padding(.leading, AppTheme.contentPadding)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: selectedRecipeIDs.count)
        }
    }

    private func filterChip(
        title: LocalizedStringResource,
        isSelected: Bool,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func selectableRecipeCard(_ recipe: Recipe) -> some View {
        let isSelected = selectedRecipeIDs.contains(recipe.persistentModelID)
        return Button {
            toggleSelection(for: recipe)
        } label: {
            ZStack(alignment: .topTrailing) {
                RecipeCardView(
                    recipe: recipe,
                    style: .grid,
                    showsNutrition: true,
                    imageMeta: .caloriesTopLeading
                )

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.accent : .primary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(8)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(recipe.localizedName)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("common.cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("common.save") {
                saveMeals()
            }
        }
    }

    private func toggleSelection(for recipe: Recipe) {
        let id = recipe.persistentModelID
        if selectedRecipeIDs.contains(id) {
            selectedRecipeIDs.remove(id)
        } else {
            selectedRecipeIDs.insert(id)
        }
    }

    private func saveMeals() {
        let existing = dayPlan.meals.filter { $0.mealType == targetMealType }

        for meal in existing {
            guard let recipeID = meal.recipe?.persistentModelID else {
                modelContext.delete(meal)
                continue
            }
            if !selectedRecipeIDs.contains(recipeID) {
                modelContext.delete(meal)
                dayPlan.meals.removeAll { $0.persistentModelID == meal.persistentModelID }
            }
        }

        let remainingRecipeIDs = Set(
            dayPlan.meals(for: targetMealType).compactMap(\.recipe?.persistentModelID)
        )

        let selectedRecipes = recipes.filter { selectedRecipeIDs.contains($0.persistentModelID) }
        for recipe in selectedRecipes {
            guard !remainingRecipeIDs.contains(recipe.persistentModelID) else { continue }
            let meal = Meal(
                mealType: targetMealType,
                date: dayPlan.date,
                recipe: recipe,
                dayPlan: dayPlan
            )
            modelContext.insert(meal)
            dayPlan.meals.append(meal)
        }

        if let weekPlan = dayPlan.weekPlan {
            WeekPlanService.syncShoppingItems(for: weekPlan, in: modelContext)
        }

        LocalPersistence.save(modelContext)
        onSave()
        dismiss()
    }
}
