import SwiftUI

struct WeekDayCarousel: View {
    let dayPlans: [DayPlan]
    @Binding var selectedDay: Date?
    let onTapEmptyMeal: (DayPlan, MealType) -> Void

    private let daySpacing: CGFloat = 12

    var body: some View {
        LazyVStack(spacing: daySpacing) {
            ForEach(dayPlans, id: \.date) { dayPlan in
                DayPlanCardView(
                    dayPlan: dayPlan,
                    isSelected: isSelected(dayPlan),
                    onTapEmptyMeal: { mealType in
                        onTapEmptyMeal(dayPlan, mealType)
                    }
                )
                .onTapGesture {
                    selectedDay = dayPlan.date
                }
            }
        }
    }

    private func isSelected(_ dayPlan: DayPlan) -> Bool {
        guard let selectedDay else { return false }
        return Calendar.current.isSameDay(selectedDay, dayPlan.date)
    }
}
