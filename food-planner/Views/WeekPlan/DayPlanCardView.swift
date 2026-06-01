import SwiftUI

struct DayPlanCardView: View {
    let dayPlan: DayPlan
    let isSelected: Bool
    let onTapEmptyMeal: (MealType) -> Void

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    private var dayTitle: String {
        dayPlan.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(dayPlan.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayTitle)
                        .font(.headline)
                    if isToday {
                        Text("weekPlan.today")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(dayMealTypes, id: \.self) { type in
                    PlannedMealSlotView(
                        mealType: type,
                        meals: dayPlan.meals(for: type),
                        onTap: { onTapEmptyMeal(type) }
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }

    private var borderWidth: CGFloat {
        isSelected || isToday ? 2 : 0
    }

    private var borderColor: Color {
        if isSelected { return .accentColor }
        if isToday { return .accentColor.opacity(0.5) }
        return .clear
    }
}
