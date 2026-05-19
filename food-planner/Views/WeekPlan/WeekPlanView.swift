import SwiftUI
import SwiftData

private struct DayPlanSheetItem: Identifiable {
    let dayPlan: DayPlan
    var id: PersistentIdentifier { dayPlan.persistentModelID }
}

struct WeekPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    @State private var currentWeekPlan: WeekPlan?
    @State private var selectedDay: Date?
    @State private var mealSheetItem: DayPlanSheetItem?

    var body: some View {
        content
            .navigationTitle("nav.weekPlan")
            .onAppear(perform: loadWeekPlan)
            .onChange(of: weekPlans.count) { _, _ in loadWeekPlan() }
            .sheet(item: $mealSheetItem) { item in
                AddMealSheet(dayPlan: item.dayPlan) {
                    syncShoppingList()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let weekPlan = currentWeekPlan {
            WeekDayCarousel(
                dayPlans: sortedDayPlans(weekPlan),
                selectedDay: $selectedDay,
                onAddMeal: presentAddMeal
            )
        } else {
            ProgressView()
        }
    }

    private func loadWeekPlan() {
        currentWeekPlan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        if let plan = currentWeekPlan {
            AppSettingsService.setActiveWeekPlan(plan, in: modelContext)
        }
        guard selectedDay == nil else { return }

        let today = currentWeekPlan?.dayPlans.first { Calendar.current.isDateInToday($0.date) }?.date
        selectedDay = today ?? Calendar.current.startOfDay(for: .now)
    }

    private func sortedDayPlans(_ weekPlan: WeekPlan) -> [DayPlan] {
        weekPlan.dayPlans.sorted { $0.date < $1.date }
    }

    private func presentAddMeal(_ dayPlan: DayPlan) {
        mealSheetItem = DayPlanSheetItem(dayPlan: dayPlan)
    }

    private func syncShoppingList() {
        guard let plan = currentWeekPlan else { return }
        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
    }
}
