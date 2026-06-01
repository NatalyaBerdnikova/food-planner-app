import SwiftUI
import SwiftData

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    let dayPlan: DayPlan
    let onSave: () -> Void

    @State private var filterTab: RecipeFilterTab
    @State private var selectedRecipe: Recipe?
    @State private var searchText = ""
    @State private var showAddRecipe = false

    init(
        dayPlan: DayPlan,
        preferredMealType: MealType = .breakfast,
        onSave: @escaping () -> Void
    ) {
        self.dayPlan = dayPlan
        self.onSave = onSave
        let tab = RecipeFilterTab(rawValue: preferredMealType.rawValue) ?? .breakfast
        _filterTab = State(initialValue: tab)
    }

    private var emptyStateHint: String {
        searchText.isEmpty
            ? String(localized: "empty.recipes.hint")
            : String(localized: "search.noResults.hint")
    }

    private var tabFilteredRecipes: [Recipe] {
        let mealType = filterTab.mealType
        return recipes.filter { recipe in
            recipe.meals.isEmpty || recipe.meals.contains { $0.mealType == mealType }
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
            .onChange(of: filterTab) { _, _ in
                selectedRecipe = nil
            }
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
        Section("addMeal.recipe") {
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
            Button("common.save") { saveMeal() }
                .disabled(selectedRecipe == nil)
        }
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        Button {
            selectedRecipe = recipe
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

                if selectedRecipe?.persistentModelID == recipe.persistentModelID {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func saveMeal() {
        guard let recipe = selectedRecipe else { return }

        if let existing = dayPlan.meals.first(where: { $0.mealType == filterTab.mealType }) {
            modelContext.delete(existing)
            dayPlan.meals.removeAll { $0.persistentModelID == existing.persistentModelID }
        }

        let meal = Meal(
            mealType: filterTab.mealType,
            date: dayPlan.date,
            recipe: recipe,
            dayPlan: dayPlan
        )
        modelContext.insert(meal)
        dayPlan.meals.append(meal)

        if let weekPlan = dayPlan.weekPlan {
            WeekPlanService.syncShoppingItems(for: weekPlan, in: modelContext)
        }

        LocalPersistence.save(modelContext)
        onSave()
        dismiss()
    }
}
