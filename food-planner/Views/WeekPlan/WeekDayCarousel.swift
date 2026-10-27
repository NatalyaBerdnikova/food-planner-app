import SwiftUI

struct WeekDayCarousel: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let dayPlans: [DayPlan]
    let targetNutrition: DailyNutrition?
    var micronutrientFocus: [MicronutrientKind] = []
    @Binding var selectedDay: Date?
    let onTapEmptyMeal: (DayPlan, MealType) -> Void

    @State private var expandedDates: Set<Date> = []

    private let daySpacing: CGFloat = 12

    private var columns: [GridItem] {
        AppTheme.dayPlanColumns(horizontalSizeClass: horizontalSizeClass, spacing: daySpacing)
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: daySpacing) {
            ForEach(dayPlans, id: \.date) { dayPlan in
                let dayKey = dayKey(for: dayPlan.date)
                DayPlanCardView(
                    dayPlan: dayPlan,
                    isExpanded: expandedDates.contains(dayKey),
                    targetNutrition: targetNutrition,
                    micronutrientFocus: micronutrientFocus,
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
        .scrollTargetLayout()
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
