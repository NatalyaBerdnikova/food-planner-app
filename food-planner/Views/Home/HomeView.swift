import SwiftUI
import SwiftData

private struct AddMealPresentation: Identifiable {
    let dayPlan: DayPlan
    var preferredMealType: MealType?
    var id: PersistentIdentifier { dayPlan.persistentModelID }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var currentWeekPlan: WeekPlan?
    @State private var appSettings: AppSettings?
    @State private var selectedDay: Date?
    @State private var addMealPresentation: AddMealPresentation?

    private let mainMealTypes: [MealType] = [.breakfast, .lunch, .dinner]
    private let recommendationColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                todayPlanSection
                otherMealsSection
                weekPlanSection
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
        .sheet(item: $addMealPresentation) { presentation in
            AddMealSheet(
                dayPlan: presentation.dayPlan,
                preferredMealType: presentation.preferredMealType
            ) {
                refresh()
            }
        }
    }

    private var todayPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let settings = appSettings {
                NutritionTargetProgressView(
                    actual: todayNutrition,
                    target: settings.targetNutrition
                )
            }

            NutritionSummaryView(nutrition: todayNutrition)

            VStack(spacing: 8) {
                ForEach(mainMealTypes, id: \.self) { type in
                    TodayMealSlotView(mealType: type, meal: meal(for: type))
                }
            }
        }
    }

    private var otherMealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("home.other")
                .font(.headline)

            if snackMeals.isEmpty {
                Text("home.otherEmpty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snackMeals) { meal in
                    TodaySnackRowView(meal: meal)
                }
            }

            Button {
                presentAddSnack()
            } label: {
                Label("home.addOther", systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
            }
            .disabled(todayDayPlan == nil)
        }
    }

    private var weekPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.weekPlan")
                    .font(.title2.bold())
                Spacer()
                NavigationLink {
                    WeekPlanView()
                } label: {
                    Text("home.openWeekPlan")
                        .font(.subheadline)
                }
            }

            Text(weekRangeFormatted)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let weekPlan = currentWeekPlan {
                WeekDayCarousel(
                    dayPlans: sortedDayPlans(weekPlan),
                    selectedDay: $selectedDay,
                    onAddMeal: { dayPlan in
                        addMealPresentation = AddMealPresentation(dayPlan: dayPlan)
                    }
                )
            } else {
                Text("home.weekNotCreated")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

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

    private var todayDayPlan: DayPlan? {
        guard let weekPlan = currentWeekPlan else { return nil }
        return weekPlan.dayPlans.first { Calendar.current.isDateInToday($0.date) }
    }

    private var snackMeals: [Meal] {
        guard let dayPlan = todayDayPlan else { return [] }
        return dayPlan.meals.filter { $0.mealType == .snack }
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

    private var weekRangeFormatted: String {
        guard let weekPlan = currentWeekPlan else {
            return String(localized: "home.weekNotCreated")
        }
        let calendar = Calendar.current
        let start = weekPlan.weekStartDate
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let formatter = Date.FormatStyle(date: .abbreviated, time: .omitted)
        return "\(start.formatted(formatter)) – \(end.formatted(formatter))"
    }

    private func sortedDayPlans(_ weekPlan: WeekPlan) -> [DayPlan] {
        weekPlan.dayPlans.sorted { $0.date < $1.date }
    }

    private func presentAddSnack() {
        guard let dayPlan = todayDayPlan else { return }
        addMealPresentation = AddMealPresentation(dayPlan: dayPlan, preferredMealType: .snack)
    }

    private func refresh() {
        appSettings = AppSettingsService.settings(in: modelContext)
        let plan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        currentWeekPlan = plan
        AppSettingsService.setActiveWeekPlan(plan, in: modelContext)
        _ = WeekPlanService.dayPlan(for: .now, in: plan, context: modelContext)

        if selectedDay == nil {
            let today = plan.dayPlans.first { Calendar.current.isDateInToday($0.date) }?.date
            selectedDay = today ?? Calendar.current.startOfDay(for: .now)
        }
    }
}

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
                Text(mealType.displayName)
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

struct TodaySnackRowView: View {
    let meal: Meal

    var body: some View {
        Group {
            if let recipe = meal.recipe {
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack {
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(.tint)
                .frame(width: 28)

            Text(meal.recipe?.name ?? String(localized: "meal.noRecipe"))
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            if meal.recipe != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
