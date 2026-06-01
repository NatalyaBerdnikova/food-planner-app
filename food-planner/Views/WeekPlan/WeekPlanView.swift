import SwiftUI
import SwiftData

struct WeekPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    @State private var currentWeekPlan: WeekPlan?
    @State private var displayedWeekStart = Calendar.current.startOfWeek(for: .now)
    @State private var selectedDay: Date?
    @State private var addMealPresentation: AddMealPresentation?

    var body: some View {
        content
            .navigationTitle("nav.weekPlan")
            .onAppear(perform: loadWeekPlan)
            .onChange(of: weekPlans.count) { _, _ in loadWeekPlan() }
            .sheet(item: $addMealPresentation) { item in
                AddMealSheet(dayPlan: item.dayPlan, preferredMealType: item.mealType) {
                    syncShoppingList()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let weekPlan = currentWeekPlan {
            ScrollView {
                VStack(spacing: 12) {
                    weekSwitcher

                    WeekDayCarousel(
                        dayPlans: sortedDayPlans(weekPlan),
                        selectedDay: $selectedDay,
                        onTapEmptyMeal: presentAddMeal
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        } else {
            ProgressView()
        }
    }

    private func loadWeekPlan() {
        let initialPlan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        displayedWeekStart = Calendar.current.startOfWeek(for: initialPlan.weekStartDate)
        setWeek(startingFrom: displayedWeekStart)
    }

    private func sortedDayPlans(_ weekPlan: WeekPlan) -> [DayPlan] {
        weekPlan.dayPlans.sorted { $0.date < $1.date }
    }

    private func presentAddMeal(_ dayPlan: DayPlan, mealType: MealType) {
        addMealPresentation = AddMealPresentation(dayPlan: dayPlan, mealType: mealType)
    }

    private func syncShoppingList() {
        guard let plan = currentWeekPlan else { return }
        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
    }

    private var weekSwitcher: some View {
        HStack {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(weekRangeTitle)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    private var weekRangeTitle: String {
        guard let weekPlan = currentWeekPlan else { return "" }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekPlan.weekStartDate)
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: start) else {
            return start.formatted(.dateTime.day().month(.abbreviated))
        }
        let startText = start.formatted(.dateTime.day().month(.abbreviated))
        let endText = endDate.formatted(.dateTime.day().month(.abbreviated))
        return "\(startText) - \(endText)"
    }

    private func shiftWeek(by offset: Int) {
        guard let newStart = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: displayedWeekStart) else {
            return
        }
        displayedWeekStart = Calendar.current.startOfWeek(for: newStart)
        setWeek(startingFrom: displayedWeekStart)
    }

    private func setWeek(startingFrom weekStart: Date) {
        let plan = WeekPlanService.weekPlan(forWeekStarting: weekStart, from: weekPlans, in: modelContext)
        currentWeekPlan = plan
        AppSettingsService.setActiveWeekPlan(plan, in: modelContext)

        let calendar = Calendar.current
        if let today = plan.dayPlans.first(where: { calendar.isDateInToday($0.date) })?.date {
            selectedDay = today
        } else {
            selectedDay = sortedDayPlans(plan).first?.date ?? calendar.startOfDay(for: weekStart)
        }
    }
}
