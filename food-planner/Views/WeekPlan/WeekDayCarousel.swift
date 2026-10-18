import SwiftUI

struct WeekDayCarousel: View {
    let dayPlans: [DayPlan]
    let targetNutrition: DailyNutrition?
    @Binding var selectedDay: Date?
    let onTapEmptyMeal: (DayPlan, MealType) -> Void

    @State private var expandedDates: Set<Date> = []

    private let daySpacing: CGFloat = 12

    var body: some View {
        LazyVStack(spacing: daySpacing) {
            ForEach(dayPlans, id: \.date) { dayPlan in
                let dayKey = dayKey(for: dayPlan.date)
                DayPlanCardView(
                    dayPlan: dayPlan,
                    isExpanded: expandedDates.contains(dayKey),
                    targetNutrition: targetNutrition,
                    onToggleExpanded: {
                        toggleExpanded(dayKey)
                        selectedDay = dayPlan.date
                    },
                    onTapEmptyMeal: { mealType in
                        onTapEmptyMeal(dayPlan, mealType)
                    }
                )
                .id(dayKey)
            }
        }
        .onAppear {
            seedExpandedDatesIfNeeded()
        }
        .onChange(of: weekIdentity) { _, _ in
            seedExpandedDatesIfNeeded(forceReset: true)
        }
    }

    private var weekIdentity: String {
        dayPlans
            .map { String(Calendar.current.startOfDay(for: $0.date).timeIntervalSince1970) }
            .joined(separator: "|")
    }

    private func dayKey(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func toggleExpanded(_ dayKey: Date) {
        if expandedDates.contains(dayKey) {
            expandedDates.remove(dayKey)
        } else {
            expandedDates.insert(dayKey)
        }
    }

    private func seedExpandedDatesIfNeeded(forceReset: Bool = false) {
        guard forceReset || expandedDates.isEmpty else { return }
        if let today = dayPlans.first(where: { Calendar.current.isDateInToday($0.date) }) {
            expandedDates = [dayKey(for: today.date)]
        } else {
            expandedDates = []
        }
    }
}
