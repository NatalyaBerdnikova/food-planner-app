import SwiftUI
import SwiftData

struct OnboardingDayPreviewStep: View {
    let dayPlan: DayPlan
    let target: DailyNutrition
    var micronutrientFocus: [MicronutrientKind] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DayPlanCardView(
                dayPlan: dayPlan,
                isExpanded: true,
                targetNutrition: target,
                micronutrientFocus: micronutrientFocus,
                onToggleExpanded: {},
                onTapEmptyMeal: { _ in },
                isCollapsible: false,
                showsSnackSlot: false,
                allowsMealEditing: true,
                opensRecipeInPreviewMode: true,
                lockedEditHint: "onboarding.dayPreview.unlockHint"
            )

            personalizedFooter
        }
    }

    private var personalizedFooter: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding.dayPreview.personalized.title")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("onboarding.dayPreview.personalized.subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                parameterChip(
                    title: "nutrition.macro.kcal.full",
                    value: "\(Int(target.calories.rounded()))"
                )
                parameterChip(
                    title: "nutrition.macro.protein.full",
                    value: "\(Int(target.protein.rounded()))g"
                )
                parameterChip(
                    title: "nutrition.macro.fat.full",
                    value: "\(Int(target.fat.rounded()))g"
                )
                parameterChip(
                    title: "nutrition.macro.carbs.full",
                    value: "\(Int(target.carbs.rounded()))g"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.accent.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .strokeBorder(AppTheme.accent.opacity(0.18), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }

    private func parameterChip(title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            AppTheme.elevated.opacity(0.92),
            in: RoundedRectangle(cornerRadius: AppTheme.nestedCardRadius, style: .continuous)
        )
    }
}

#Preview {
    let container = FoodPlannerSchema.previewContainer
    let context = container.mainContext
    let target = DailyNutrition(calories: 1994, protein: 130, fat: 70, carbs: 220)
    let dayPlan = OnboardingDayPreviewFactory.makeDayPlan(
        in: context,
        matching: target,
        micronutrientFocus: [.fiber, .vitaminD3, .iron]
    ) ?? DayPlan(date: .now)

    return NavigationStack {
        ScrollView {
            OnboardingDayPreviewStep(
                dayPlan: dayPlan,
                target: target,
                micronutrientFocus: [.fiber, .vitaminD3, .iron]
            )
            .padding(24)
        }
        .background(AppTheme.canvas)
    }
    .modelContainer(container)
}
