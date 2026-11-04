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

            MealPlanTargetsCard(
                target: target,
                micronutrientFocus: micronutrientFocus
            )
        }
    }
}

#Preview {
    let container = FoodPlannerSchema.previewContainer
    let target = DailyNutrition(calories: 1994, protein: 130, fat: 70, carbs: 220)

    return NavigationStack {
        ScrollView {
            OnboardingDayPreviewStep(
                dayPlan: DayPlan(date: .now),
                target: target,
                micronutrientFocus: [.fiber, .vitaminD3, .iron]
            )
            .padding(24)
        }
        .background(AppTheme.canvas)
    }
    .modelContainer(container)
}
