import Foundation
import SwiftData

enum WeekPlanService {
    /// План на календарную неделю, в которую попадает `date` (для «Сегодня» — текущая неделя).
    @MainActor
    static func weekPlan(containing date: Date, from weekPlans: [WeekPlan], in context: ModelContext) -> WeekPlan {
        let weekStart = Calendar.current.startOfWeek(for: date)
        return weekPlan(forWeekStarting: weekStart, from: weekPlans, in: context)
    }

    @MainActor
    static func currentWeekPlan(from weekPlans: [WeekPlan], in context: ModelContext) -> WeekPlan {
        weekPlan(containing: .now, from: weekPlans, in: context)
    }

    @MainActor
    static func todayDayPlan(from weekPlans: [WeekPlan], in context: ModelContext) -> DayPlan {
        let plan = currentWeekPlan(from: weekPlans, in: context)
        return dayPlan(for: .now, in: plan, context: context)
    }

    @MainActor
    static func weekPlan(forWeekStarting weekStart: Date, from weekPlans: [WeekPlan], in context: ModelContext) -> WeekPlan {
        let normalized = Calendar.current.startOfWeek(for: weekStart)

        if let existing = weekPlans.first(where: {
            Calendar.current.isSameDay($0.weekStartDate, normalized)
        }) {
            ensureDayPlansExist(for: existing, weekStart: normalized, in: context)
            AppSettingsService.settings(in: context).activeWeekPlan = existing
            LocalPersistence.save(context)
            return existing
        }

        let plan = WeekPlan(weekStartDate: normalized)
        context.insert(plan)
        ensureDayPlansExist(for: plan, weekStart: normalized, in: context)
        AppSettingsService.settings(in: context).activeWeekPlan = plan
        LocalPersistence.save(context)
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
        LocalPersistence.save(context)
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
        LocalPersistence.save(context)
    }
}
