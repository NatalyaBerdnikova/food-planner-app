import Foundation
import SwiftData

enum OnboardingDayPreviewFactory {
    @MainActor
    static func makeDayPlan(
        in context: ModelContext,
        matching target: DailyNutrition,
        micronutrientFocus: [MicronutrientKind]
    ) -> DayPlan? {
        MealPlanGenerator.makePreviewDayPlan(
            in: context,
            matching: target,
            micronutrientFocus: micronutrientFocus
        )
    }

    @MainActor
    static func discard(_ dayPlan: DayPlan, in context: ModelContext) {
        MealPlanGenerator.discardPreviewDayPlan(dayPlan, in: context)
    }
}
