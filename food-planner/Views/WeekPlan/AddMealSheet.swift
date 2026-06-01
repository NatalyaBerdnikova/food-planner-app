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
    @State private var showAddRecipe = false

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
        return base.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                targetMealHeader
                filterControls
                recipesSection
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "search.recipes")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                addRecipeFooter
            }
            .navigationTitle("addMeal.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAddRecipe) {
                NavigationStack {
                    AddRecipeView()
                }
            }
        }
    }

    private var targetMealHeader: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: targetMealIcon)
                    .foregroundStyle(.tint)
                Text(targetMealTypeLabel)
                    .font(.subheadline.weight(.medium))
            }
        } footer: {
            Text("addMeal.targetFooter")
        }
    }

    private var filterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecipeFilterTab.allCases) { tab in
                    filterChip(tab)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
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
        }
        .buttonStyle(.plain)
    }

    private var recipesSection: some View {
        Section {
            if filteredRecipes.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "empty.recipes" : "search.noResults",
                    systemImage: "magnifyingglass",
                    description: Text(emptyStateHint)
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredRecipes) { recipe in
                    recipeRow(recipe)
                }
            }
        } header: {
            Text("addMeal.recipe")
        } footer: {
            if !selectedRecipeIDs.isEmpty {
                Text("addMeal.selectedCount \(selectedRecipeIDs.count)")
            }
        }
    }

    private var addRecipeFooter: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                showAddRecipe = true
            } label: {
                Label("addRecipe.title", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("common.cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("common.save") { saveMeals() }
        }
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        let isSelected = selectedRecipeIDs.contains(recipe.persistentModelID)
        return Button {
            toggleSelection(for: recipe)
        } label: {
            HStack(spacing: 12) {
                RecipeImageView(imageData: recipe.imageData, cornerRadius: 8)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name)
                        .foregroundStyle(.primary)
                    Text(L10n.kcalPer100g(Int(recipe.caloriesPer100g)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.tertiaryLabel))
            }
        }
        .buttonStyle(.plain)
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

    private var targetMealTypeLabel: LocalizedStringResource {
        targetMealType == .snack ? "filter.other" : targetMealType.displayName
    }

    private var targetMealIcon: String {
        switch targetMealType {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "ellipsis.circle.fill"
        }
    }
}
