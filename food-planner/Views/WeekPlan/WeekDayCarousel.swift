import SwiftUI

struct WeekDayCarousel: View {
    let dayPlans: [DayPlan]
    @Binding var selectedDay: Date?
    let onAddMeal: (DayPlan) -> Void

    private let daySpacing: CGFloat = 12
    private let horizontalInset: CGFloat = 20

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: daySpacing) {
                ForEach(dayPlans, id: \.date) { dayPlan in
                    dayCard(for: dayPlan)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedDay)
        .safeAreaPadding(.horizontal, horizontalInset)
    }

    private func dayCard(for dayPlan: DayPlan) -> some View {
        DayPlanCardView(
            dayPlan: dayPlan,
            isSelected: isSelected(dayPlan),
            onAddMeal: { onAddMeal(dayPlan) }
        )
        .containerRelativeFrame(.horizontal, count: 1, spacing: daySpacing)
        .id(dayPlan.date)
    }

    private func isSelected(_ dayPlan: DayPlan) -> Bool {
        guard let selectedDay else { return false }
        return Calendar.current.isSameDay(selectedDay, dayPlan.date)
    }
}
