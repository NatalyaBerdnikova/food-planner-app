import SwiftUI

struct DayPlanCardView: View {
    let dayPlan: DayPlan
    let isExpanded: Bool
    let targetNutrition: DailyNutrition?
    let onToggleExpanded: () -> Void
    let onTapEmptyMeal: (MealType) -> Void

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    private var dayTitle: String {
        dayPlan.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(dayPlan.date)
    }

    private var dayNutrition: DailyNutrition {
        NutritionCalculator.from(dayPlan: dayPlan)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggleExpanded) {
                HStack(spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(dayTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if isToday {
                            Text("weekPlan.today")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(dayMealTypes, id: \.self) { type in
                        PlannedMealSlotView(
                            mealType: type,
                            meals: dayPlan.meals(for: type),
                            onTap: { onTapEmptyMeal(type) }
                        )
                    }
                }
            } else {
                NutritionSummaryView(
                    nutrition: dayNutrition,
                    target: targetNutrition,
                    embedded: true,
                    macroLabelStyle: .full
                )
            }
        }
        .padding(AppTheme.contentPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    private var borderWidth: CGFloat {
        isToday ? 2 : 0
    }

    private var borderColor: Color {
        isToday ? .accentColor.opacity(0.5) : .clear
    }
}
