import SwiftUI

struct DayPlanCardView: View {
    let dayPlan: DayPlan
    let isExpanded: Bool
    let targetNutrition: DailyNutrition?
    let micronutrientFocus: [MicronutrientKind]
    let onToggleExpanded: () -> Void
    let onTapEmptyMeal: (MealType) -> Void
    var isCollapsible: Bool = true
    var showsSnackSlot: Bool = true
    var allowsMealEditing: Bool = true
    var opensRecipeInPreviewMode: Bool = false
    var lockedEditHint: LocalizedStringKey? = nil

    @State private var showMicronutrients = false

    private var dayMealTypes: [MealType] {
        showsSnackSlot
            ? [.breakfast, .lunch, .dinner, .snack]
            : [.breakfast, .lunch, .dinner]
    }

    private var showsExpandedContent: Bool {
        !isCollapsible || isExpanded
    }

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
            dayHeader

            NutritionSummaryView(
                nutrition: dayNutrition,
                target: targetNutrition,
                embedded: true,
                macroLabelStyle: .full
            )
            .padding(.top, 12)

            if showsExpandedContent {
                VStack(spacing: 16) {
                    ForEach(dayMealTypes, id: \.self) { type in
                        PlannedMealSlotView(
                            mealType: type,
                            meals: dayPlan.meals(for: type),
                            onTap: { onTapEmptyMeal(type) },
                            allowsEditing: allowsMealEditing,
                            opensRecipeInPreviewMode: opensRecipeInPreviewMode,
                            lockedEditHint: lockedEditHint
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
        .motionSafeAnimation(isCollapsible ? .easeInOut(duration: 0.25) : nil, value: isExpanded)
        .sheet(isPresented: $showMicronutrients) {
            MicronutrientDetailSheet(
                totals: dayTotals,
                micronutrientFocus: micronutrientFocus
            )
        }
    }

    @ViewBuilder
    private var dayHeader: some View {
        let titleRow = HStack(spacing: 12) {
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

            if isCollapsible {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                    .contentShape(Rectangle())
            }
        }

        if isCollapsible {
            Button(action: onToggleExpanded) {
                titleRow
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(dayTitle))
            .accessibilityValue(Text(isExpanded ? "accessibility.expanded" : "accessibility.collapsed"))
            .accessibilityHint("accessibility.toggleDay")
        } else {
            titleRow
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(dayTitle))
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
