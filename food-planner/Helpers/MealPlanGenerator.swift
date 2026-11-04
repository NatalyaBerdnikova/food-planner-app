import Foundation
import SwiftData

enum WeekPlanGenerationStage: Int, CaseIterable, Identifiable {
    case pickingRecipes
    case fillingDays
    case checkingMacros
    case saving
    case ready

    var id: Int { rawValue }

    var localizationKey: String {
        switch self {
        case .pickingRecipes: "weekPlan.generate.stage.picking"
        case .fillingDays: "weekPlan.generate.stage.filling"
        case .checkingMacros: "weekPlan.generate.stage.macros"
        case .saving: "weekPlan.generate.stage.saving"
        case .ready: "weekPlan.generate.stage.ready"
        }
    }
}

@MainActor
enum MealPlanGenerator {
    /// Допуск ±20% по каждому макросу за день (1 порция рецепта как есть).
    private static let softMinCoverage = 0.80
    private static let softMaxCoverage = 1.20
    /// Допуск ±10% по сумме макросов за всю неделю относительно цели × число дней.
    private static let weekSoftMinCoverage = 0.90
    private static let weekSoftMaxCoverage = 1.10
    private static let maxRecipeOccurrencesPerWeek = 3
    private static let poolLimit = 16
    private static let maxItemsPerDay = 5
    private static let topCombinationCount = 12
    private static let weekRebalanceAttempts = 8
    private static let combinationYieldStride = 250

    struct PlannedItem {
        let catalogRecipeId: String
        let source: Recipe
        let mealType: MealType
        let scale: Double
    }

    struct DayBlueprint {
        let items: [PlannedItem]
    }

    fileprivate struct MacroCache {
        private let byCatalogId: [String: DailyNutrition]

        init(recipes: [Recipe]) {
            var map: [String: DailyNutrition] = [:]
            map.reserveCapacity(recipes.count)
            for recipe in recipes {
                guard let id = recipe.catalogRecipeId else { continue }
                map[id] = NutritionCalculator.nutritionPerServing(for: recipe)
            }
            byCatalogId = map
        }

        func nutrition(for recipe: Recipe) -> DailyNutrition {
            guard let id = recipe.catalogRecipeId else {
                return NutritionCalculator.nutritionPerServing(for: recipe)
            }
            return byCatalogId[id] ?? .zero
        }

        func sum(_ recipes: [Recipe]) -> DailyNutrition {
            recipes.reduce(into: DailyNutrition.zero) { partial, recipe in
                let nutrition = self.nutrition(for: recipe)
                partial.calories += nutrition.calories
                partial.protein += nutrition.protein
                partial.fat += nutrition.fat
                partial.carbs += nutrition.carbs
            }
        }
    }

    static func makePreviewDayPlan(
        in context: ModelContext,
        matching target: DailyNutrition,
        micronutrientFocus: [MicronutrientKind]
    ) async -> DayPlan? {
        _ = micronutrientFocus
        await FoodCatalogSeeder.seedIfNeeded(in: context)
        await RecipeCatalogStore.seedIfNeeded(in: context)

        let candidates = candidateRecipes(in: context)
        let macros = MacroCache(recipes: candidates)
        guard let blueprint = await blueprint(
            matching: target,
            candidates: candidates,
            usageCounts: [:],
            macros: macros
        ) else { return nil }

        let today = Calendar.current.startOfDay(for: .now)
        let dayPlan = DayPlan(date: today)
        context.insert(dayPlan)
        apply(blueprint, to: dayPlan, in: context, clearExisting: false)
        MealPlanGenerationPending.previewSnapshot = snapshot(from: blueprint)
        return dayPlan
    }

    static func discardPreviewDayPlan(_ dayPlan: DayPlan, in context: ModelContext) {
        removeMeals(from: dayPlan, in: context)
        context.delete(dayPlan)
    }

    static func blueprint(
        matching target: DailyNutrition,
        candidates: [Recipe],
        usageCounts: [String: Int],
        pinned: DayBlueprint? = nil,
        varietySalt: Int = 0
    ) async -> DayBlueprint? {
        await blueprint(
            matching: target,
            candidates: candidates,
            usageCounts: usageCounts,
            macros: MacroCache(recipes: candidates),
            pinned: pinned,
            varietySalt: varietySalt
        )
    }

    private static func blueprint(
        matching target: DailyNutrition,
        candidates: [Recipe],
        usageCounts: [String: Int],
        macros: MacroCache,
        pinned: DayBlueprint? = nil,
        varietySalt: Int = 0
    ) async -> DayBlueprint? {
        if let pinned, !pinned.items.isEmpty {
            return pinned
        }

        let available = availableRecipes(from: candidates, usageCounts: usageCounts)
        let poolSource = available.isEmpty ? candidates : available
        if let day = await buildDay(from: poolSource, matching: target, macros: macros, varietySalt: varietySalt) {
            return day
        }
        return await buildDay(
            from: candidates,
            matching: target,
            macros: macros,
            varietySalt: varietySalt &+ 17
        )
    }

    static func blueprint(from snapshot: MealPlanDaySnapshot, candidates: [Recipe]) -> DayBlueprint? {
        let byId = RecipeCollections.catalogRecipesByID(from: candidates)
        var items: [PlannedItem] = []
        var used = Set<String>()
        for slot in snapshot.slots {
            guard let mealType = slot.mealType,
                  let source = byId[slot.catalogRecipeId],
                  used.insert(slot.catalogRecipeId).inserted
            else { continue }
            items.append(
                PlannedItem(
                    catalogRecipeId: slot.catalogRecipeId,
                    source: source,
                    mealType: mealType,
                    scale: 1
                )
            )
        }
        guard !items.isEmpty else { return nil }
        return DayBlueprint(items: items)
    }

    static func snapshot(from blueprint: DayBlueprint) -> MealPlanDaySnapshot {
        MealPlanDaySnapshot(
            slots: blueprint.items.map {
                .init(
                    mealTypeRaw: $0.mealType.rawValue,
                    catalogRecipeId: $0.catalogRecipeId,
                    scale: 1
                )
            },
            createdAt: .now
        )
    }

    static func generateWeek(
        weekPlan: WeekPlan,
        matching target: DailyNutrition,
        micronutrientFocus: [MicronutrientKind],
        pinnedToday: DayBlueprint?,
        replaceExisting: Bool,
        in context: ModelContext,
        onStage: @MainActor (WeekPlanGenerationStage) -> Void
    ) async {
        _ = micronutrientFocus
        onStage(.pickingRecipes)
        await FoodCatalogSeeder.seedIfNeeded(in: context)
        await RecipeCatalogStore.seedIfNeeded(in: context)
        await Task.yield()

        let candidates = candidateRecipes(in: context)
        let macros = MacroCache(recipes: candidates)
        await Task.yield()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = weekPlan.dayPlans.sorted { $0.date < $1.date }

        onStage(.fillingDays)
        var usageCounts: [String: Int] = [:]
        if let pinnedToday {
            addUsage(&usageCounts, ids: pinnedToday.items.map(\.catalogRecipeId))
        }

        for (dayIndex, dayPlan) in days.enumerated() {
            if Task.isCancelled { return }
            let isToday = calendar.isDate(dayPlan.date, inSameDayAs: today)
            let hasMeals = !dayPlan.meals.isEmpty

            if !replaceExisting && hasMeals && !(isToday && pinnedToday != nil) {
                addUsage(&usageCounts, ids: Array(catalogIds(in: dayPlan)))
                continue
            }

            let pinned = isToday ? pinnedToday : nil
            let daySalt = dayIndex &* 31 &+ calendar.component(.day, from: dayPlan.date)
            guard let dayBlueprint = await blueprint(
                matching: target,
                candidates: candidates,
                usageCounts: usageCounts,
                macros: macros,
                pinned: pinned,
                varietySalt: daySalt
            ) else { continue }

            apply(dayBlueprint, to: dayPlan, in: context, clearExisting: true)
            addUsage(&usageCounts, ids: dayBlueprint.items.map(\.catalogRecipeId))
            await Task.yield()
        }

        onStage(.checkingMacros)
        await rebalanceWeekIfNeeded(
            weekPlan: weekPlan,
            matching: target,
            candidates: candidates,
            macros: macros,
            pinnedToday: pinnedToday,
            in: context
        )
        await Task.yield()

        onStage(.saving)
        WeekPlanService.syncShoppingItems(for: weekPlan, in: context)
        LocalPersistence.save(context)
        await Task.yield()
        onStage(.ready)
    }

    static func apply(
        _ blueprint: DayBlueprint,
        to dayPlan: DayPlan,
        in context: ModelContext,
        clearExisting: Bool
    ) {
        if clearExisting {
            removeMeals(from: dayPlan, in: context)
        }

        var meals = dayPlan.meals
        for item in blueprint.items {
            let meal = Meal(
                mealType: item.mealType,
                date: dayPlan.date,
                recipe: item.source,
                dayPlan: dayPlan
            )
            context.insert(meal)
            meals.append(meal)
        }
        dayPlan.meals = meals
    }

    static func removeMeals(from dayPlan: DayPlan, in context: ModelContext) {
        for meal in dayPlan.meals {
            context.delete(meal)
        }
        dayPlan.meals = []
    }

    private static func catalogIds(in dayPlan: DayPlan) -> Set<String> {
        Set(dayPlan.meals.compactMap(\.recipe?.catalogRecipeId))
    }

    private static func catalogIdList(in dayPlan: DayPlan) -> [String] {
        dayPlan.meals.compactMap(\.recipe?.catalogRecipeId)
    }

    private static func addUsage(_ counts: inout [String: Int], ids: [String]) {
        for id in ids {
            counts[id, default: 0] += 1
        }
    }

    private static func removeUsage(_ counts: inout [String: Int], ids: [String]) {
        for id in ids {
            guard let current = counts[id] else { continue }
            if current <= 1 {
                counts.removeValue(forKey: id)
            } else {
                counts[id] = current - 1
            }
        }
    }

    private static func availableRecipes(
        from candidates: [Recipe],
        usageCounts: [String: Int]
    ) -> [Recipe] {
        candidates.filter { recipe in
            guard let id = recipe.catalogRecipeId else { return false }
            return usageCounts[id, default: 0] < maxRecipeOccurrencesPerWeek
        }
    }

    private static func weekUsageCounts(in weekPlan: WeekPlan) -> [String: Int] {
        var counts: [String: Int] = [:]
        for day in weekPlan.dayPlans {
            addUsage(&counts, ids: catalogIdList(in: day))
        }
        return counts
    }

    private static func weekMacros(in weekPlan: WeekPlan) -> DailyNutrition {
        weekPlan.dayPlans.reduce(into: DailyNutrition.zero) { partial, dayPlan in
            let daily = NutritionCalculator.from(dayPlan: dayPlan)
            partial.calories += daily.calories
            partial.protein += daily.protein
            partial.fat += daily.fat
            partial.carbs += daily.carbs
        }
    }

    private static func isWithinWeekBand(_ actual: DailyNutrition, dailyTarget: DailyNutrition, dayCount: Int) -> Bool {
        guard dayCount > 0 else { return true }
        let weekTarget = DailyNutrition(
            calories: dailyTarget.calories * Double(dayCount),
            protein: dailyTarget.protein * Double(dayCount),
            fat: dailyTarget.fat * Double(dayCount),
            carbs: dailyTarget.carbs * Double(dayCount)
        )
        let ratios = [
            ratio(actual.calories, weekTarget.calories),
            ratio(actual.protein, weekTarget.protein),
            ratio(actual.fat, weekTarget.fat),
            ratio(actual.carbs, weekTarget.carbs),
        ]
        return ratios.allSatisfy { $0 >= weekSoftMinCoverage && $0 <= weekSoftMaxCoverage }
    }

    private static func rebalanceWeekIfNeeded(
        weekPlan: WeekPlan,
        matching target: DailyNutrition,
        candidates: [Recipe],
        macros: MacroCache,
        pinnedToday: DayBlueprint?,
        in context: ModelContext
    ) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = weekPlan.dayPlans.sorted { $0.date < $1.date }
        guard !days.isEmpty else { return }

        var usageCounts = weekUsageCounts(in: weekPlan)

        for attempt in 0..<weekRebalanceAttempts {
            if Task.isCancelled { return }
            let actual = weekMacros(in: weekPlan)
            if isWithinWeekBand(actual, dailyTarget: target, dayCount: days.count) {
                return
            }

            let rebuildCandidates = days.compactMap { dayPlan -> (DayPlan, Double)? in
                let isToday = calendar.isDate(dayPlan.date, inSameDayAs: today)
                if isToday, pinnedToday != nil { return nil }
                guard !dayPlan.meals.isEmpty else { return nil }
                let dayActual = NutritionCalculator.from(dayPlan: dayPlan)
                let score = fitness(actual: dayActual, target: target)
                return (dayPlan, score)
            }
            .sorted { $0.1 < $1.1 }

            guard let weakest = rebuildCandidates.first else { return }

            let dayPlan = weakest.0
            let previousIds = catalogIdList(in: dayPlan)
            removeUsage(&usageCounts, ids: previousIds)

            let daySalt = attempt &* 47
                &+ calendar.component(.day, from: dayPlan.date)
                &+ calendar.component(.month, from: dayPlan.date)
            guard let replacement = await blueprint(
                matching: target,
                candidates: candidates,
                usageCounts: usageCounts,
                macros: macros,
                pinned: nil,
                varietySalt: daySalt
            ) else {
                addUsage(&usageCounts, ids: previousIds)
                return
            }

            apply(replacement, to: dayPlan, in: context, clearExisting: true)
            addUsage(&usageCounts, ids: replacement.items.map(\.catalogRecipeId))
            await Task.yield()
        }
    }

    private static func candidateRecipes(in context: ModelContext) -> [Recipe] {
        let all = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        return RecipeCollections.deduplicatedCatalogRecipes(from: all.filter(\.isVisibleInApp))
            .filter { NutritionCalculator.nutritionPerServing(for: $0).calories > 50 }
    }

    private static func buildDay(
        from candidates: [Recipe],
        matching target: DailyNutrition,
        macros: MacroCache,
        varietySalt: Int
    ) async -> DayBlueprint? {
        guard !candidates.isEmpty, target.calories > 0 else { return nil }

        guard var items = await selectCoreThree(
            from: candidates,
            matching: target,
            macros: macros,
            varietySalt: varietySalt
        ) else {
            return fallbackDay(from: candidates, matching: target, varietySalt: varietySalt)
        }

        var used = Set(items.map(\.catalogRecipeId))
        ensureRequiredMealTypes(in: &items, from: candidates, used: &used, macros: macros)

        while items.count < maxItemsPerDay {
            let actual = macros.sum(items.map(\.source))
            guard !isWithinBand(actual, target: target) else { break }
            guard ratio(actual.calories, target.calories) < softMinCoverage else { break }

            let deficitCalories = max(0, target.calories * softMinCoverage - actual.calories)
            guard deficitCalories > 80 else { break }

            let mealType = nextMealType(for: items)
            let snackPool = pool(
                for: mealType,
                from: candidates,
                targetSlotCalories: deficitCalories,
                macros: macros
            ).filter {
                guard let id = $0.catalogRecipeId else { return false }
                return !used.contains(id)
            }
            guard let pick = snackPool.max(by: {
                fitness(
                    actual: macros.sum(items.map(\.source) + [$0]),
                    target: target
                ) < fitness(
                    actual: macros.sum(items.map(\.source) + [$1]),
                    target: target
                )
            }), let catalogId = pick.catalogRecipeId else { break }

            let improved = fitness(
                actual: macros.sum(items.map(\.source) + [pick]),
                target: target
            )
            let current = fitness(actual: actual, target: target)
            guard improved > current else { break }

            used.insert(catalogId)
            items.append(
                PlannedItem(
                    catalogRecipeId: catalogId,
                    source: pick,
                    mealType: mealType,
                    scale: 1
                )
            )
        }

        return DayBlueprint(items: items)
    }

    private static func selectCoreThree(
        from candidates: [Recipe],
        matching target: DailyNutrition,
        macros: MacroCache,
        varietySalt: Int
    ) async -> [PlannedItem]? {
        let slotCalories = target.calories / 3
        let breakfastPool = rotated(
            pool(for: .breakfast, from: candidates, targetSlotCalories: slotCalories, macros: macros),
            by: varietySalt
        )
        let lunchPool = rotated(
            pool(for: .lunch, from: candidates, targetSlotCalories: slotCalories, macros: macros),
            by: varietySalt &+ 3
        )
        let dinnerPool = rotated(
            pool(for: .dinner, from: candidates, targetSlotCalories: slotCalories, macros: macros),
            by: varietySalt &+ 7
        )

        var ranked: [(sources: [Recipe], score: Double)] = []
        var combinationsChecked = 0

        for breakfast in breakfastPool {
            for lunch in lunchPool {
                for dinner in dinnerPool {
                    combinationsChecked += 1
                    if combinationsChecked.isMultiple(of: combinationYieldStride) {
                        await Task.yield()
                        if Task.isCancelled { return nil }
                    }

                    guard let bId = breakfast.catalogRecipeId,
                          let lId = lunch.catalogRecipeId,
                          let dId = dinner.catalogRecipeId
                    else { continue }
                    guard Set([bId, lId, dId]).count == 3 else { continue }

                    let base = macros.sum([breakfast, lunch, dinner])
                    guard base.calories > 0 else { continue }
                    let score = fitness(actual: base, target: target)
                    ranked.append(([breakfast, lunch, dinner], score))
                }
            }
        }

        ranked.sort { $0.score > $1.score }
        let top = Array(ranked.prefix(topCombinationCount))
        guard !top.isEmpty else { return nil }
        let pick = top[abs(varietySalt) % top.count]

        let types: [MealType] = [.breakfast, .lunch, .dinner]
        return zip(pick.sources, types).compactMap { source, type in
            guard let id = source.catalogRecipeId else { return nil }
            return PlannedItem(
                catalogRecipeId: id,
                source: source,
                mealType: type,
                scale: 1
            )
        }
    }

    private static func fallbackDay(
        from candidates: [Recipe],
        matching target: DailyNutrition,
        varietySalt: Int
    ) -> DayBlueprint? {
        let rotatedCandidates = rotated(candidates, by: varietySalt)
        let picks = Array(rotatedCandidates.prefix(3))
        guard picks.count == 3 else { return nil }
        let types: [MealType] = [.breakfast, .lunch, .dinner]
        let items = zip(picks, types).compactMap { source, type -> PlannedItem? in
            guard let id = source.catalogRecipeId else { return nil }
            return PlannedItem(catalogRecipeId: id, source: source, mealType: type, scale: 1)
        }
        return items.count == 3 ? DayBlueprint(items: items) : nil
    }

    private static func nextMealType(for items: [PlannedItem]) -> MealType {
        if !items.contains(where: { $0.mealType == .snack }) {
            return .snack
        }
        let counts = Dictionary(grouping: items, by: \.mealType).mapValues(\.count)
        return [.breakfast, .lunch, .dinner].min {
            counts[$0, default: 0] < counts[$1, default: 0]
        } ?? .snack
    }

    private static func ensureRequiredMealTypes(
        in items: inout [PlannedItem],
        from candidates: [Recipe],
        used: inout Set<String>,
        macros: MacroCache
    ) {
        let slotCalories = max(
            macros.sum(items.map(\.source)).calories / 3,
            300
        )
        for required in [MealType.breakfast, .lunch, .dinner] {
            guard !items.contains(where: { $0.mealType == required }) else { continue }
            guard let pick = pool(
                for: required,
                from: candidates,
                targetSlotCalories: slotCalories,
                macros: macros
            ).first(where: {
                guard let id = $0.catalogRecipeId else { return false }
                return !used.contains(id)
            }), let id = pick.catalogRecipeId else { continue }
            used.insert(id)
            items.append(
                PlannedItem(
                    catalogRecipeId: id,
                    source: pick,
                    mealType: required,
                    scale: 1
                )
            )
        }
    }

    private static func pool(
        for mealType: MealType,
        from candidates: [Recipe],
        targetSlotCalories: Double,
        macros: MacroCache
    ) -> [Recipe] {
        let tagged = candidates.filter {
            $0.mealTypeTags.isEmpty || $0.mealTypeTags.contains(mealType)
        }
        let source = tagged.isEmpty ? candidates : tagged
        let slotTarget = max(targetSlotCalories, 120)
        return Array(
            source
                .sorted { lhs, rhs in
                    let left = macros.nutrition(for: lhs)
                    let right = macros.nutrition(for: rhs)
                    let leftCalFit = abs(left.calories - slotTarget)
                    let rightCalFit = abs(right.calories - slotTarget)
                    if abs(leftCalFit - rightCalFit) > 40 {
                        return leftCalFit < rightCalFit
                    }
                    let leftProteinFit = abs(ratio(left.protein, slotTarget * 0.045) - 1)
                    let rightProteinFit = abs(ratio(right.protein, slotTarget * 0.045) - 1)
                    if abs(leftProteinFit - rightProteinFit) > 0.15 {
                        return leftProteinFit < rightProteinFit
                    }
                    return left.calories > right.calories
                }
                .prefix(poolLimit)
        )
    }

    private static func isWithinBand(_ actual: DailyNutrition, target: DailyNutrition) -> Bool {
        let ratios = [
            ratio(actual.calories, target.calories),
            ratio(actual.protein, target.protein),
            ratio(actual.fat, target.fat),
            ratio(actual.carbs, target.carbs),
        ]
        return ratios.allSatisfy { $0 >= softMinCoverage && $0 <= softMaxCoverage }
    }

    private static func fitness(actual: DailyNutrition, target: DailyNutrition) -> Double {
        let ratios = [
            ratio(actual.calories, target.calories),
            ratio(actual.protein, target.protein),
            ratio(actual.fat, target.fat),
            ratio(actual.carbs, target.carbs),
        ]
        let minimum = ratios.min() ?? 0
        let maximum = ratios.max() ?? 0
        let distancePenalty = ratios.reduce(0.0) { $0 + abs($1 - 1) } * 120
        let underPenalty = ratios.reduce(0.0) { $0 + max(0, softMinCoverage - $1) } * 280
        let overPenalty = ratios.reduce(0.0) { $0 + max(0, $1 - softMaxCoverage) } * 420

        if minimum >= softMinCoverage && maximum <= softMaxCoverage {
            return 2_000 - distancePenalty
        }
        return minimum * 120 - underPenalty - overPenalty
    }

    private static func rotated<T>(_ items: [T], by offset: Int) -> [T] {
        guard !items.isEmpty else { return items }
        let shift = ((offset % items.count) + items.count) % items.count
        guard shift != 0 else { return items }
        return Array(items[shift...]) + Array(items[..<shift])
    }

    private static func ratio(_ actual: Double, _ target: Double) -> Double {
        guard target > 0 else { return 1 }
        return actual / target
    }
}
