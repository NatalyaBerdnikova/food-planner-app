import SwiftUI
import SwiftData

struct WeekPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    @State private var currentWeekPlan: WeekPlan?
    @State private var expandedDay: Date?
    @State private var dayPlanForNewMeal: DayPlan?
    @State private var showAddMeal = false

    var body: some View {
        Group {
            if let weekPlan = currentWeekPlan {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(sortedDayPlans(weekPlan), id: \.date) { dayPlan in
                            DayPlanCardView(
                                dayPlan: dayPlan,
                                isExpanded: isExpanded(dayPlan),
                                onToggle: { toggleDay(dayPlan) },
                                onAddMeal: { presentAddMeal(for: dayPlan) }
                            )
                        }
                    }
                    .padding()
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("nav.weekPlan")
        .onAppear { loadWeekPlan() }
        .onChange(of: weekPlans.count) { _, _ in loadWeekPlan() }
        .sheet(isPresented: $showAddMeal) {
            if let dayPlan = dayPlanForNewMeal {
                AddMealSheet(dayPlan: dayPlan) {
                    if let plan = currentWeekPlan {
                        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
                    }
                }
            }
        }
    }

    private func loadWeekPlan() {
        currentWeekPlan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        if expandedDay == nil, let today = currentWeekPlan?.dayPlans.first(where: {
            Calendar.current.isDateInToday($0.date)
        }) {
            expandedDay = today.date
        }
    }

    private func sortedDayPlans(_ weekPlan: WeekPlan) -> [DayPlan] {
        weekPlan.dayPlans.sorted { $0.date < $1.date }
    }

    private func isExpanded(_ dayPlan: DayPlan) -> Bool {
        guard let expandedDay else { return false }
        return Calendar.current.isSameDay(expandedDay, dayPlan.date)
    }

    private func toggleDay(_ dayPlan: DayPlan) {
        if isExpanded(dayPlan) {
            expandedDay = nil
        } else {
            expandedDay = dayPlan.date
        }
    }

    private func presentAddMeal(for dayPlan: DayPlan) {
        dayPlanForNewMeal = dayPlan
        showAddMeal = true
    }
}
