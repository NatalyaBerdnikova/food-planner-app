import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImportCoordinator.self) private var importCoordinator
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var isTodayExpanded = false
    @State private var recommendationSearch = ""
    @State private var unfavoriteCandidate: Recipe?
    @State private var addMealPresentation: AddMealPresentation?
    @State private var pasteImportRequest: PasteImportRequest?
    @State private var featuredRecipeOverride: Recipe?

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    private var appSettings: AppSettings? { settingsList.first }

    private var currentWeekPlan: WeekPlan? {
        WeekPlanService.findCurrentWeekPlan(in: weekPlans)
    }

    private var featuredRecipe: Recipe? {
        featuredRecipeOverride ?? RecipeDiscoveryService.recipeOfTheDay(from: recipes)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                recipeOfTheDaySection
                recommendationsSection
                todayNutritionCard
                todayMealsSection
                weekPlanCard
                importCTACard
            }
            .padding(AppTheme.contentPadding)
        }
        .appScreenBackground()
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
        .sheet(item: $pasteImportRequest) { _ in
            PasteImportSheet()
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
                Text("favorites.remove.message \(recipe.localizedName)")
            }
        }
    }

    @ViewBuilder
    private var recipeOfTheDaySection: some View {
        if let recipe = featuredRecipe {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    AppSectionHeader(title: "home.recipeOfTheDay", systemImage: "sun.max.fill", fillsWidth: false)
                    Spacer(minLength: 0)
                    Button {
                        featuredRecipeOverride = RecipeDiscoveryService.randomRecipe(
                            from: catalogRecipes.isEmpty ? recipes : catalogRecipes,
                            excluding: recipe.persistentModelID
                        )
                    } label: {
                        Label("home.randomRecipe", systemImage: "shuffle")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                    .accessibilityHint("home.randomRecipe")
                }

                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    RecipeCardView(recipe: recipe, style: .hero)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var importCTACard: some View {
        Button {
            pasteImportRequest = PasteImportRequest()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.warmFill)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.warmFill.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("home.import.cta.title")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("home.import.cta.subtitle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppTheme.warmFill)
                    .frame(width: 3)
                    .padding(.vertical, 12)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("home.import.cta.subtitle")
    }

    private var todayNutritionCard: some View {
        AppSectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isTodayExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        AppSectionHeader(title: "home.today", systemImage: "chart.bar.fill", fillsWidth: false)
                        Spacer(minLength: 0)
                        Image(systemName: isTodayExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
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
                        target: appSettings?.targetNutrition,
                        embedded: true,
                        macroLabelStyle: .compact
                    )
                }
            }
        }
    }

    private var todayMealsSection: some View {
        VStack(spacing: 10) {
            ForEach(dayMealTypes, id: \.self) { type in
                PlannedMealSlotView(
                    mealType: type,
                    meals: meals(for: type),
                    onTap: { presentAddMeal(for: type) },
                    style: .home
                )
            }
        }
    }

    private var weekPlanCard: some View {
        NavigationLink {
            WeekPlanView()
        } label: {
            AppSectionCard {
                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader(title: "home.weekPlan", systemImage: "calendar")

                    if let weekPlan = currentWeekPlan {
                        Text(weekRangeFormatted(for: weekPlan))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("home.weekNotCreated")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("home.openWeekPlan")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("home.openWeekPlan")
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "home.recommendations", systemImage: "sparkles")

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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.sectionRailSpacing) {
                        ForEach(filteredCatalogRecipes) { recipe in
                            recommendationCard(recipe)
                                .frame(width: AppTheme.recipeRailCardWidth)
                        }
                    }
                    .padding(.vertical, 2)
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
                RecipeCardView(recipe: recipe, style: .rail)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

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
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(8)
            .accessibilityLabel(
                isFavorite
                    ? String(localized: "accessibility.removeFavorite")
                    : String(localized: "accessibility.addFavorite")
            )
        }
    }

    private var catalogRecipes: [Recipe] {
        RecipeCollections.catalogRecipes(from: recipes)
    }

    private var filteredCatalogRecipes: [Recipe] {
        let query = recommendationSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return catalogRecipes }
        return catalogRecipes.filter { $0.matchesSearch(query) }
    }

    private var todayDayPlan: DayPlan? {
        guard let weekPlan = currentWeekPlan else { return nil }
        let calendar = Calendar.current
        return weekPlan.dayPlans.first { calendar.isDateInToday($0.date) }
    }

    private var todayNutrition: DailyNutrition {
        guard let dayPlan = todayDayPlan else { return .zero }
        return NutritionCalculator.from(dayPlan: dayPlan)
    }

    private func meals(for type: MealType) -> [Meal] {
        todayDayPlan?.meals(for: type) ?? []
    }

    private func presentAddMeal(for mealType: MealType) {
        let dayPlan = WeekPlanService.todayDayPlan(from: weekPlans, in: modelContext)
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
        let plan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        AppSettingsService.setActiveWeekPlan(plan, in: modelContext)
        _ = WeekPlanService.todayDayPlan(from: weekPlans, in: modelContext)
    }
}
