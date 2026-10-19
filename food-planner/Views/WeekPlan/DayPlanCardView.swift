import SwiftUI

struct DayPlanCardView: View {
    let dayPlan: DayPlan
    let isExpanded: Bool
    let targetNutrition: DailyNutrition?
    let micronutrientFocus: [MicronutrientKind]
    let onToggleExpanded: () -> Void
    let onTapEmptyMeal: (MealType) -> Void

    @State private var showMicronutrients = false

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

    private var dayTotals: NutrientTotals {
        NutritionCalculator.totals(from: dayPlan)
    }

    private var focusedMicronutrients: [MicronutrientKind] {
        micronutrientFocus.isEmpty
            ? [.fiber, .vitaminD3, .iron]
            : micronutrientFocus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggleExpanded) {
                HStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(dayTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if isToday {
                            Text("weekPlan.today")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                        .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(dayTitle))
            .accessibilityValue(Text(isExpanded ? "accessibility.expanded" : "accessibility.collapsed"))
            .accessibilityHint("accessibility.toggleDay")

            NutritionSummaryView(
                nutrition: dayNutrition,
                target: targetNutrition,
                embedded: true,
                macroLabelStyle: .full
            )
            .padding(.top, 12)

            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(dayMealTypes, id: \.self) { type in
                        PlannedMealSlotView(
                            mealType: type,
                            meals: dayPlan.meals(for: type),
                            onTap: { onTapEmptyMeal(type) }
                        )
                    }
                }
                .padding(.top, 16)

                micronutrientsSection
                    .padding(.top, 16)
            }
        }
        .padding(AppTheme.contentPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        }
        .motionSafeAnimation(.easeInOut(duration: 0.25), value: isExpanded)
        .sheet(isPresented: $showMicronutrients) {
            MicronutrientDetailSheet(
                totals: dayTotals,
                micronutrientFocus: micronutrientFocus
            )
        }
    }

    private var micronutrientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("recipe.micronutrients")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Button {
                    showMicronutrients = true
                } label: {
                    Text("common.more")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.nestedFill, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("recipe.micronutrients")
            }

            ForEach(focusedMicronutrients) { kind in
                MicronutrientProgressRow(
                    kind: kind,
                    actual: dayTotals.value(for: kind)
                )
            }
        }
    }

    private var borderWidth: CGFloat {
        isToday ? 2 : 0
    }

    private var borderColor: Color {
        isToday ? .accentColor.opacity(0.5) : .clear
    }
}
