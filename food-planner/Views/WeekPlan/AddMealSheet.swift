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
    @State private var selectedRecipeIDs: Set<PersistentIdentifier>
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
    }

    private var navigationTitle: LocalizedStringResource {
        targetMealType == .snack ? "filter.other" : targetMealType.displayName
    }

    private var emptyStateHint: String {
        searchText.isEmpty
            ? String(localized: "empty.recipes.hint")
            : String(localized: "search.noResults.hint")
    }

    private var tabFilteredRecipes: [Recipe] {
        guard let filterMealType = filterTab.mealType else {
            return recipes
        }
        return recipes.filter { recipe in
            recipe.meals.isEmpty || recipe.meals.contains { $0.mealType == filterMealType }
        }
    }

    private var filteredRecipes: [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let base = tabFilteredRecipes
        guard !query.isEmpty else { return base }
        return base.filter { $0.matchesSearch(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if filteredRecipes.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "empty.recipes" : "search.noResults",
                        systemImage: "magnifyingglass",
                        description: Text(emptyStateHint)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredRecipes) { recipe in
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
                    filterChip(tab)
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

    private func filterChip(_ tab: RecipeFilterTab) -> some View {
        Button {
            filterTab = tab
        } label: {
            Text(tab.displayName)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(filterTab == tab ? Color.accentColor : Color(.tertiarySystemFill))
                .foregroundStyle(filterTab == tab ? Color.white : Color.primary)
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
                    showsCommunityLikes: false
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
