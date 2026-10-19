import SwiftUI
import SwiftData

struct WeekPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var displayedWeekStart = Calendar.current.startOfWeek(for: .now)
    @State private var selectedDay: Date?
    @State private var addMealPresentation: AddMealPresentation?

    private var displayedWeekPlan: WeekPlan? {
        let normalized = Calendar.current.startOfWeek(for: displayedWeekStart)
        return weekPlans.first { Calendar.current.isSameDay($0.weekStartDate, normalized) }
    }

    private var targetNutrition: DailyNutrition? {
        settingsList.first?.targetNutrition
    }

    private var micronutrientFocus: [MicronutrientKind] {
        settingsList.first?.profileMicronutrientFocus ?? []
    }

    var body: some View {
        content
            .navigationTitle("nav.weekPlan")
            .task(id: displayedWeekStart) {
                ensureDisplayedWeekPlan()
            }
            .onChange(of: weekPlans.count) { _, _ in
                updateSelectedDayIfNeeded()
            }
            .sheet(item: $addMealPresentation) { item in
                AddMealSheet(dayPlan: item.dayPlan, preferredMealType: item.mealType) {
                    syncShoppingList()
                }
                .appFormSheetPresentation()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let weekPlan = displayedWeekPlan {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.sectionSpacing) {
                        WeekRangeSwitcher(weekStart: $displayedWeekStart)

                        WeekDayCarousel(
                            dayPlans: sortedDayPlans(weekPlan),
                            targetNutrition: targetNutrition,
                            micronutrientFocus: micronutrientFocus,
                            selectedDay: $selectedDay,
                            onTapEmptyMeal: presentAddMeal
                        )
                    }
                    .padding(.horizontal, AppTheme.contentPadding)
                    .padding(.bottom, AppTheme.contentPadding)
                    .appWideReadableWidth()
                }
                .appScreenBackground()
                .onAppear {
                    scrollToCurrentDay(using: proxy)
                }
                .onChange(of: displayedWeekStart) { _, _ in
                    scrollToCurrentDay(using: proxy)
                }
            }
        } else {
            ProgressView()
        }
    }

    private func scrollToCurrentDay(using proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        guard let todayPlan = displayedWeekPlan?.dayPlans.first(where: { calendar.isDateInToday($0.date) }) else {
            return
        }
        let dayID = calendar.startOfDay(for: todayPlan.date)
        DispatchQueue.main.async {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                proxy.scrollTo(dayID, anchor: .top)
            }
        }
    }

    private func sortedDayPlans(_ weekPlan: WeekPlan) -> [DayPlan] {
        weekPlan.dayPlans.sorted { $0.date < $1.date }
    }

    private func presentAddMeal(_ dayPlan: DayPlan, mealType: MealType) {
        addMealPresentation = AddMealPresentation(dayPlan: dayPlan, mealType: mealType)
    }

    private func syncShoppingList() {
        guard let plan = displayedWeekPlan else { return }
        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
    }

    private func ensureDisplayedWeekPlan() {
        let plan = WeekPlanService.weekPlan(
            forWeekStarting: displayedWeekStart,
            from: weekPlans,
            in: modelContext
        )
        AppSettingsService.setActiveWeekPlan(plan, in: modelContext)
        updateSelectedDay(for: plan)
    }

    private func updateSelectedDayIfNeeded() {
        guard let plan = displayedWeekPlan else { return }
        updateSelectedDay(for: plan)
    }

    private func updateSelectedDay(for plan: WeekPlan) {
        let calendar = Calendar.current
        if let today = plan.dayPlans.first(where: { calendar.isDateInToday($0.date) })?.date {
            selectedDay = today
        } else {
            selectedDay = sortedDayPlans(plan).first?.date ?? calendar.startOfDay(for: plan.weekStartDate)
        }
    }
}
