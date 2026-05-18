import Foundation
import SwiftData

enum WeekPlanService {
    @MainActor
    static func currentWeekPlan(from weekPlans: [WeekPlan], in context: ModelContext) -> WeekPlan {
        let weekStart = Calendar.current.startOfWeek(for: .now)

        if let existing = weekPlans.first(where: {
            Calendar.current.isSameDay($0.weekStartDate, weekStart)
        }) {
            ensureDayPlansExist(for: existing, weekStart: weekStart, in: context)
            return existing
        }

        let plan = WeekPlan(weekStartDate: weekStart)
        context.insert(plan)
        ensureDayPlansExist(for: plan, weekStart: weekStart, in: context)
        return plan
    }

    @MainActor
    private static func ensureDayPlansExist(
        for weekPlan: WeekPlan,
        weekStart: Date,
        in context: ModelContext
    ) {
        let calendar = Calendar.current
        let weekDates = calendar.weekDates(startingFrom: weekStart)

        for date in weekDates {
            let exists = weekPlan.dayPlans.contains { calendar.isSameDay($0.date, date) }
            guard !exists else { continue }

            let dayPlan = DayPlan(date: calendar.startOfDay(for: date), weekPlan: weekPlan)
            context.insert(dayPlan)
            weekPlan.dayPlans.append(dayPlan)
        }

        weekPlan.dayPlans.sort { $0.date < $1.date }
    }

    @MainActor
    static func dayPlan(for date: Date, in weekPlan: WeekPlan, context: ModelContext) -> DayPlan {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)

        if let existing = weekPlan.dayPlans.first(where: { calendar.isSameDay($0.date, target) }) {
            return existing
        }

        let dayPlan = DayPlan(date: target, weekPlan: weekPlan)
        context.insert(dayPlan)
        weekPlan.dayPlans.append(dayPlan)
        weekPlan.dayPlans.sort { $0.date < $1.date }
        return dayPlan
    }

    @MainActor
    static func syncShoppingItems(for weekPlan: WeekPlan, in context: ModelContext) {
        for aggregated in weekPlan.aggregatedShoppingList {
            let exists = weekPlan.shoppingItems.contains {
                $0.name.caseInsensitiveCompare(aggregated.name) == .orderedSame
                    && $0.unit == aggregated.unit
            }
            guard !exists else { continue }

            let item = ShoppingItem(
                name: aggregated.name,
                quantity: aggregated.quantity,
                unit: aggregated.unit,
                weekPlan: weekPlan
            )
            context.insert(item)
            weekPlan.shoppingItems.append(item)
        }
    }
}
