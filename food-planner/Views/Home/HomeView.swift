import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var currentWeekPlan: WeekPlan?
    @State private var appSettings: AppSettings?
    @State private var isTodayExpanded = false

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
    private let recommendationColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                todayNutritionCard
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

                VStack(spacing: 8) {
                    ForEach(dayMealTypes, id: \.self) { type in
                        TodayMealSlotView(mealType: type, meal: meal(for: type))
                    }
                }
            } else {
                NutritionSummaryView(
                    nutrition: todayNutrition,
                    title: "nutrition.title.day",
                    embedded: true,
                    macroLabelStyle: .compact
                )
            }
        }
        .homeCardStyle()
    }

    // MARK: - Week plan card

    private var weekPlanCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("home.weekPlan")
                .font(.headline)

            if let weekPlan = currentWeekPlan {
                Text(weekRangeFormatted(for: weekPlan))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                NutritionSummaryView(
                    nutrition: NutritionCalculator.averageDaily(for: weekPlan),
                    title: "nutrition.title.weekAverage",
                    embedded: true,
                    macroLabelStyle: .compact
                )

                NavigationLink {
                    WeekPlanView()
                } label: {
                    Text("home.openWeekPlan")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Text("home.weekNotCreated")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .homeCardStyle()
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.recommendations")
                .font(.title2.bold())

            if recommendedRecipes.isEmpty {
                Text("home.addRecipesHint")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: recommendationColumns, spacing: 12) {
                    ForEach(recommendedRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeCardView(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Data

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

    private var recommendedRecipes: [Recipe] {
        Array(recipes.prefix(4))
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
                slotContent
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
                    .foregroundStyle(.primary)
            }

            Spacer()

            if let recipe = meal?.recipe {
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
