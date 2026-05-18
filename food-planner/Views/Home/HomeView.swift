import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var currentWeekPlan: WeekPlan?

    private let mainMealTypes: [MealType] = [.breakfast, .lunch, .dinner]
    private let recommendationColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                weekPlanLinkSection
                todayPlanSection
                recommendationsSection
            }
            .padding()
        }
        .navigationTitle("Главная")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Настройки")
            }
        }
        .onAppear { loadWeekPlan() }
    }

    private var weekPlanLinkSection: some View {
        NavigationLink {
            WeekPlanView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Текущий план питания")
                        .font(.headline)
                    Text(weekRangeText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var todayPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Сегодня")
                .font(.title2.bold())

            NutritionSummaryView(nutrition: todayNutrition)

            VStack(spacing: 8) {
                ForEach(mainMealTypes, id: \.self) { type in
                    TodayMealSlotView(mealType: type, meal: meal(for: type))
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Рекомендации")
                .font(.title2.bold())

            if recommendedRecipes.isEmpty {
                Text("Добавьте рецепты, чтобы увидеть рекомендации")
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

    private var todayNutrition: DailyNutrition {
        guard let dayPlan = todayDayPlan else { return .zero }
        return DailyNutrition.from(dayPlan: dayPlan)
    }

    private func meal(for type: MealType) -> Meal? {
        todayDayPlan?.meals.first { $0.mealType == type }
    }

    private var recommendedRecipes: [Recipe] {
        Array(recipes.prefix(4))
    }

    private var weekRangeText: String {
        guard let weekPlan = currentWeekPlan else { return "Неделя не создана" }
        let calendar = Calendar.current
        let start = weekPlan.weekStartDate
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let formatter = Date.FormatStyle(date: .abbreviated, time: .omitted)
        return "\(start.formatted(formatter)) – \(end.formatted(formatter))"
    }

    private func loadWeekPlan() {
        currentWeekPlan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
    }
}

struct TodayMealSlotView: View {
    let mealType: MealType
    let meal: Meal?

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(mealType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(meal?.recipe?.name ?? "Не запланировано")
                    .font(.body)
            }

            Spacer()

            if let recipe = meal?.recipe {
                Text("\(Int(recipe.caloriesPer100g)) ккал")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        case .snack: "leaf.fill"
        }
    }
}
