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
    @State private var selectedKeys: Set<String>
    @State private var pinnedSelectedKeys: Set<String>
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

        let existingKeys = Set(
            dayPlan.meals(for: preferredMealType).compactMap { meal in
                meal.recipe.flatMap(Self.selectionKey(for:))
            }
        )
        _selectedKeys = State(initialValue: existingKeys)
        _pinnedSelectedKeys = State(initialValue: existingKeys)
    }

    private var navigationTitle: LocalizedStringResource {
        targetMealType == .snack ? "filter.other" : targetMealType.displayName
    }

    private var emptyStateHint: String {
        let hasFilters = !searchText.isEmpty || showFavoritesOnly || showMineOnly || filterTab != .all
        return hasFilters
            ? L10n.string("search.noResults.hint")
            : L10n.string("empty.recipes.hint")
    }

    private var favoriteIds: Set<String> {
        RecipeFavoritesService.favoriteIds(in: modelContext)
    }

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var baseFilteredRecipes: [Recipe] {
        var result = RecipeCollections.libraryRecipes(from: recipes)

        if showMineOnly {
            result = result.filter(\.isUserCreated)
        }

        if showFavoritesOnly {
            result = RecipeFavoritesService.favoriteRecipes(from: result, favoriteIds: favoriteIds)
        }

        if let filterMealType = filterTab.mealType {
            result = result.filter { $0.matchesMealTypeFilter(filterMealType) }
        }

        return result
    }

    private var nameMatchedRecipes: [Recipe] {
        guard !searchQuery.isEmpty else { return baseFilteredRecipes }
        return baseFilteredRecipes.filter { $0.matchesNameSearch(searchQuery) }
    }

    private var ingredientMatchedRecipes: [Recipe] {
        guard !searchQuery.isEmpty, nameMatchedRecipes.isEmpty else { return [] }
        return baseFilteredRecipes.filter { $0.matchesIngredientSearch(searchQuery) }
    }

    private func pinnedFirst(_ recipes: [Recipe]) -> [Recipe] {
        let pinned = recipes.filter { recipe in
            selectionKey(for: recipe).map(pinnedSelectedKeys.contains) ?? false
        }
        let rest = recipes.filter { recipe in
            !(selectionKey(for: recipe).map(pinnedSelectedKeys.contains) ?? false)
        }
        return pinned + rest
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if nameMatchedRecipes.isEmpty && ingredientMatchedRecipes.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "empty.recipes" : "search.noResults",
                        systemImage: "magnifyingglass",
                        description: Text(emptyStateHint)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if !nameMatchedRecipes.isEmpty {
                    recipeGrid(pinnedFirst(nameMatchedRecipes))
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("search.byIngredient.title")
                                .font(.headline)
                            Text("search.byIngredient.subtitle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        recipeGrid(
                            pinnedFirst(ingredientMatchedRecipes),
                            includesOuterPadding: false
                        )
                    }
                    .padding(AppTheme.contentPadding)
                    .padding(.bottom, selectedKeys.isEmpty ? 0 : 56)
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
        .appFormSheetPresentation()
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
        if !selectedKeys.isEmpty {
            Text("addMeal.selectedCount \(selectedKeys.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.elevated, in: Capsule())
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
                .padding(.leading, AppTheme.contentPadding)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .motionSafeAnimation(.easeInOut(duration: 0.2), value: selectedKeys.count)
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
            .frame(minHeight: AppTheme.minTapTarget)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    @ViewBuilder
    private func recipeGrid(_ recipes: [Recipe], includesOuterPadding: Bool = true) -> some View {
        let grid = LazyVGrid(columns: columns, spacing: 12) {
            ForEach(recipes) { recipe in
                selectableRecipeCard(recipe)
            }
        }

        if includesOuterPadding {
            grid
                .padding(AppTheme.contentPadding)
                .padding(.bottom, selectedKeys.isEmpty ? 0 : 56)
        } else {
            grid
        }
    }

    private func selectableRecipeCard(_ recipe: Recipe) -> some View {
        let isSelected = selectionKey(for: recipe).map(selectedKeys.contains) ?? false
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
                    .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                    .background(AppTheme.contentOverlayFill, in: Circle())
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
        guard let key = selectionKey(for: recipe) else { return }
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
        } else {
            selectedKeys.insert(key)
        }
    }

    private func saveMeals() {
        let existing = dayPlan.meals.filter { $0.mealType == targetMealType }

        for meal in existing {
            guard let recipe = meal.recipe,
                  let key = selectionKey(for: recipe),
                  selectedKeys.contains(key) else {
                modelContext.delete(meal)
                dayPlan.meals.removeAll { $0.persistentModelID == meal.persistentModelID }
                continue
            }
        }

        let remainingKeys = Set(
            dayPlan.meals(for: targetMealType).compactMap { meal in
                meal.recipe.flatMap(Self.selectionKey(for:))
            }
        )

        var libraryByKey: [String: Recipe] = [:]
        for recipe in RecipeCollections.libraryRecipes(from: recipes) {
            guard let key = selectionKey(for: recipe) else { continue }
            libraryByKey[key] = recipe
        }

        for key in selectedKeys where !remainingKeys.contains(key) {
            guard let recipe = libraryByKey[key] else { continue }
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
        AppAnalytics.logPlanEdit(editType: "add")
        onSave()
        dismiss()
    }

    private func selectionKey(for recipe: Recipe) -> String? {
        Self.selectionKey(for: recipe)
    }

    private static func selectionKey(for recipe: Recipe) -> String? {
        if let catalogId = recipe.catalogRecipeId, !catalogId.isEmpty {
            return "catalog:\(catalogId)"
        }
        if let userId = recipe.userRecipeId, !userId.isEmpty {
            return "user:\(userId)"
        }
        return "persistent:\(String(describing: recipe.persistentModelID))"
    }
}
