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
    @State private var showProSubscriptionOffer = false

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
    private let recommendationColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private let accentTeal = Color(red: 0.06, green: 0.33, blue: 0.45)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                todayNutritionCard
                ProSubscriptionPromoView {
                    showProSubscriptionOffer = true
                }
                todayMealsSection
                weekPlanCard
                recommendationsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("nav.today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.headline)
                        .foregroundStyle(accentTeal)
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
        .sheet(isPresented: $showProSubscriptionOffer) {
            ProSubscriptionOfferSheet()
                .presentationDetents([.medium, .large])
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
        homeSectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isTodayExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        sectionIcon("chart.bar.fill")
                        Text("home.today")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
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

    // MARK: - Today meals

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

    // MARK: - Week plan card

    private var weekPlanCard: some View {
        NavigationLink {
            WeekPlanView()
        } label: {
            homeSectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        sectionIcon("calendar")
                        Text("home.weekPlan")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }

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
                        .padding(.vertical, 12)
                        .background(accentTeal, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("home.openWeekPlan")
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                    .frame(width: 34, height: 34)
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
        currentWeekPlan = dayPlan.weekPlan
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
        _ = WeekPlanService.todayDayPlan(from: weekPlans, in: modelContext)
    }

    // MARK: - Section styling

    private func homeSectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    private func sectionIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(accentTeal)
            .frame(width: 30, height: 30)
            .background(accentTeal.opacity(0.1), in: Circle())
    }
}
