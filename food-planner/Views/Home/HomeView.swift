import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var currentWeekPlan: WeekPlan?
    @State private var appSettings: AppSettings?
    @State private var isTodayExpanded = false
    @State private var recommendationSearch = ""
    @State private var unfavoriteCandidate: Recipe?
    @State private var addMealPresentation: AddMealPresentation?

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
    private let recommendationColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                todayNutritionCard
                todayMealsSection
                weekPlanCard
                recommendationsSection
            }
            .padding()
        }
        .navigationTitle("nav.today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("accessibility.settings")
            }
        }
        .onAppear { refresh() }
        .animation(.easeInOut(duration: 0.25), value: isTodayExpanded)
        .sheet(item: $addMealPresentation) { item in
            AddMealSheet(dayPlan: item.dayPlan, preferredMealType: item.mealType) {
                refresh()
            }
        }
        .alert(
            "favorites.remove.title",
            isPresented: Binding(
                get: { unfavoriteCandidate != nil },
                set: { if !$0 { unfavoriteCandidate = nil } }
            )
        ) {
            Button("common.cancel", role: .cancel) {
                unfavoriteCandidate = nil
            }
            Button("favorites.remove.confirm", role: .destructive) {
                if let recipe = unfavoriteCandidate {
                    RecipeFavoritesService.setFavorite(recipe, favorite: false, in: modelContext)
                }
                unfavoriteCandidate = nil
            }
        } message: {
            if let recipe = unfavoriteCandidate {
                Text("favorites.remove.message \(recipe.name)")
            }
        }
    }

    // MARK: - Today nutrition card

    private var todayNutritionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isTodayExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("home.today")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isTodayExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isTodayExpanded {
                if let settings = appSettings {
                    NutritionTargetProgressView(
                        actual: todayNutrition,
                        target: settings.targetNutrition,
                        macroLabelStyle: .full,
                        embedded: true
                    )
                }
            } else {
                NutritionSummaryView(
                    nutrition: todayNutrition,
                    embedded: true,
                    macroLabelStyle: .compact
                )
            }
        }
        .homeCardStyle()
    }

    // MARK: - Today meals

    private var todayMealsSection: some View {
        VStack(spacing: 8) {
            ForEach(dayMealTypes, id: \.self) { type in
                TodayMealSlotView(mealType: type, meal: meal(for: type)) {
                    presentAddMeal(for: type)
                }
            }
        }
    }

    // MARK: - Week plan card

    private var weekPlanCard: some View {
        NavigationLink {
            WeekPlanView()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.weekPlan")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let weekPlan = currentWeekPlan {
                        Text(weekRangeFormatted(for: weekPlan))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("home.weekNotCreated")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .homeCardStyle()
        .accessibilityLabel("home.openWeekPlan")
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.recommendations")
                .font(.title2.bold())

            if !catalogRecipes.isEmpty {
                TextField("home.recommendations.search", text: $recommendationSearch)
                    .textFieldStyle(.roundedBorder)
            }

            if catalogRecipes.isEmpty {
                Text("home.catalogEmpty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if filteredCatalogRecipes.isEmpty {
                Text("home.recommendations.noResults")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: recommendationColumns, spacing: 12) {
                    ForEach(filteredCatalogRecipes) { recipe in
                        recommendationCard(recipe)
                    }
                }
            }
        }
    }

    private func recommendationCard(_ recipe: Recipe) -> some View {
        let isFavorite = RecipeFavoritesService.isFavorite(recipe, in: modelContext)
        return ZStack(alignment: .topTrailing) {
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                RecipeCardView(recipe: recipe)
            }
            .buttonStyle(.plain)

            Button {
                if isFavorite {
                    unfavoriteCandidate = recipe
                } else {
                    RecipeFavoritesService.setFavorite(recipe, favorite: true, in: modelContext)
                }
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isFavorite ? .red : .secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
            .accessibilityLabel(
                isFavorite
                    ? String(localized: "accessibility.removeFavorite")
                    : String(localized: "accessibility.addFavorite")
            )
        }
    }

    // MARK: - Data

    private var catalogRecipes: [Recipe] {
        RecipeCollections.catalogRecipes(from: recipes)
    }

    private var filteredCatalogRecipes: [Recipe] {
        let query = recommendationSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return catalogRecipes }
        return catalogRecipes.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    private var todayDayPlan: DayPlan? {
        guard let weekPlan = currentWeekPlan else { return nil }
        return weekPlan.dayPlans.first { Calendar.current.isDateInToday($0.date) }
    }

    private var todayNutrition: DailyNutrition {
        guard let dayPlan = todayDayPlan else { return .zero }
        return NutritionCalculator.from(dayPlan: dayPlan)
    }

    private func meal(for type: MealType) -> Meal? {
        todayDayPlan?.meals.first { $0.mealType == type }
    }

    private func presentAddMeal(for mealType: MealType) {
        guard let weekPlan = currentWeekPlan else { return }
        let dayPlan = WeekPlanService.dayPlan(for: .now, in: weekPlan, context: modelContext)
        addMealPresentation = AddMealPresentation(dayPlan: dayPlan, mealType: mealType)
    }

    private func weekRangeFormatted(for weekPlan: WeekPlan) -> String {
        let calendar = Calendar.current
        let start = weekPlan.weekStartDate
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let formatter = Date.FormatStyle(date: .abbreviated, time: .omitted)
        return "\(start.formatted(formatter)) – \(end.formatted(formatter))"
    }

    private func refresh() {
        appSettings = AppSettingsService.settings(in: modelContext)
        let plan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        currentWeekPlan = plan
        AppSettingsService.setActiveWeekPlan(plan, in: modelContext)
        _ = WeekPlanService.dayPlan(for: .now, in: plan, context: modelContext)
    }
}

// MARK: - Card style

private extension View {
    func homeCardStyle() -> some View {
        padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Meal slots

struct TodayMealSlotView: View {
    let mealType: MealType
    let meal: Meal?
    var onAddMeal: () -> Void

    var body: some View {
        Group {
            if let recipe = meal?.recipe {
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    slotContent
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onAddMeal) {
                    slotContent
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var slotContent: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(mealTypeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(meal?.recipe?.name ?? String(localized: "home.notPlanned"))
                    .font(.body)
                    .foregroundStyle(meal?.recipe == nil ? .secondary : .primary)
            }

            Spacer()

            if meal?.recipe == nil {
                Image(systemName: "plus.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if let recipe = meal?.recipe {
                let nutrition = NutritionCalculator.recipeNutrition(recipe)
                let calories = nutrition.totalWeightGrams > 0
                    ? Int(nutrition.total.calories.rounded())
                    : Int(recipe.caloriesPer100g)
                Text(L10n.kcalShort(calories))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var mealTypeLabel: LocalizedStringResource {
        mealType == .snack ? "filter.other" : mealType.displayName
    }

    private var iconName: String {
        switch mealType {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "ellipsis.circle.fill"
        }
    }
}
