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
    /// Soft band: keep natural portions when the day already lands here.
    private static let softMinCoverage = 0.88
    private static let softMaxCoverage = 1.08
    private static let poolLimit = 14
    private static let maxItemsPerDay = 7
    private static let topCombinationCount = 10

    struct PlannedItem {
        let catalogRecipeId: String
        let source: Recipe
        let mealType: MealType
        let scale: Double
    }

    struct DayBlueprint {
        let items: [PlannedItem]
    }

    static func makePreviewDayPlan(
        in context: ModelContext,
        matching target: DailyNutrition,
        micronutrientFocus: [MicronutrientKind]
    ) -> DayPlan? {
        _ = micronutrientFocus
        FoodCatalogSeeder.seedIfNeeded(in: context)
        RecipeCatalogStore.seedIfNeeded(in: context)

        guard let blueprint = blueprint(
            matching: target,
            candidates: candidateRecipes(in: context),
            avoiding: []
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
        avoiding avoidIds: Set<String>,
        pinned: DayBlueprint? = nil,
        varietySalt: Int = 0
    ) -> DayBlueprint? {
        if let pinned, !pinned.items.isEmpty {
            return pinned
        }

        let available = candidates.filter { recipe in
            guard let id = recipe.catalogRecipeId else { return false }
            return !avoidIds.contains(id)
        }
        let poolSource = available.isEmpty ? candidates : available
        return buildDay(from: poolSource, matching: target, varietySalt: varietySalt)
            ?? buildDay(from: candidates, matching: target, varietySalt: varietySalt &+ 17)
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
                    scale: slot.scale
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
                    scale: $0.scale
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
        try? await Task.sleep(for: .milliseconds(350))

        let candidates = candidateRecipes(in: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = weekPlan.dayPlans.sorted { $0.date < $1.date }

        onStage(.fillingDays)
        var usedAcrossWeek = Set<String>()
        if let pinnedToday {
            usedAcrossWeek.formUnion(pinnedToday.items.map(\.catalogRecipeId))
        }

        for (dayIndex, dayPlan) in days.enumerated() {
            if Task.isCancelled { return }
            let isToday = calendar.isDate(dayPlan.date, inSameDayAs: today)
            let hasMeals = !dayPlan.meals.isEmpty

            if !replaceExisting && hasMeals && !(isToday && pinnedToday != nil) {
                usedAcrossWeek.formUnion(catalogIds(in: dayPlan))
                continue
            }

            let pinned = isToday ? pinnedToday : nil
            let daySalt = dayIndex &* 31 &+ calendar.component(.day, from: dayPlan.date)
            guard let dayBlueprint = blueprint(
                matching: target,
                candidates: candidates,
                avoiding: usedAcrossWeek,
                pinned: pinned,
                varietySalt: daySalt
            ) else { continue }

            apply(dayBlueprint, to: dayPlan, in: context, clearExisting: true)
            usedAcrossWeek.formUnion(dayBlueprint.items.map(\.catalogRecipeId))
            try? await Task.sleep(for: .milliseconds(120))
        }

        onStage(.checkingMacros)
        try? await Task.sleep(for: .milliseconds(400))

        onStage(.saving)
        WeekPlanService.syncShoppingItems(for: weekPlan, in: context)
        LocalPersistence.save(context)
        try? await Task.sleep(for: .milliseconds(250))
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
            let clone = cloneRecipe(item.source, factor: item.scale, in: context)
            let meal = Meal(
                mealType: item.mealType,
                date: dayPlan.date,
                recipe: clone,
                dayPlan: dayPlan
            )
            context.insert(meal)
            meals.append(meal)
        }
        dayPlan.meals = meals
    }

    static func removeMeals(from dayPlan: DayPlan, in context: ModelContext) {
        let meals = dayPlan.meals
        for meal in meals {
            let recipe = meal.recipe
            context.delete(meal)
            if let recipe, shouldDeletePlanClone(recipe, in: context) {
                context.delete(recipe)
            }
        }
        dayPlan.meals = []
    }

    private static func catalogIds(in dayPlan: DayPlan) -> Set<String> {
        Set(dayPlan.meals.compactMap(\.recipe?.catalogRecipeId))
    }

    private static func shouldDeletePlanClone(_ recipe: Recipe, in context: ModelContext) -> Bool {
        guard let catalogId = recipe.catalogRecipeId else { return false }
        let all = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        return all.contains {
            $0.persistentModelID != recipe.persistentModelID && $0.catalogRecipeId == catalogId
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
        varietySalt: Int
    ) -> DayBlueprint? {
        guard !candidates.isEmpty, target.calories > 0 else { return nil }

        guard var items = selectCoreThree(from: candidates, matching: target, varietySalt: varietySalt) else {
            return fallbackDay(from: candidates, matching: target, varietySalt: varietySalt)
        }

        var used = Set(items.map(\.catalogRecipeId))

        while items.count < maxItemsPerDay {
            let actual = macrosSum(items.map(\.source))
            let calorieRatio = ratio(actual.calories, target.calories)
            let proteinRatio = ratio(actual.protein, target.protein)
            guard calorieRatio < softMinCoverage || proteinRatio < softMinCoverage else { break }

            let deficitCalories = max(0, target.calories * softMinCoverage - actual.calories)
            guard deficitCalories > 80 else { break }

            let mealType = nextMealType(for: items)
            let rotatedPool = rotated(
                pool(for: mealType, from: candidates).filter {
                    guard let id = $0.catalogRecipeId else { return false }
                    return !used.contains(id)
                },
                by: varietySalt &+ items.count
            )
            guard let pick = rotatedPool.min(by: {
                abs(NutritionCalculator.nutritionPerServing(for: $0).calories - deficitCalories)
                    < abs(NutritionCalculator.nutritionPerServing(for: $1).calories - deficitCalories)
            }), let catalogId = pick.catalogRecipeId else { break }

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

        ensureRequiredMealTypes(in: &items, from: candidates, used: &used, scale: 1)

        let base = macrosSum(items.map(\.source))
        let scale = naturalScale(baseCalories: base.calories, targetCalories: target.calories)
        items = items.map {
            PlannedItem(
                catalogRecipeId: $0.catalogRecipeId,
                source: $0.source,
                mealType: $0.mealType,
                scale: scale
            )
        }
        return DayBlueprint(items: items)
    }

    private static func selectCoreThree(
        from candidates: [Recipe],
        matching target: DailyNutrition,
        varietySalt: Int
    ) -> [PlannedItem]? {
        let breakfastPool = rotated(pool(for: .breakfast, from: candidates), by: varietySalt)
        let lunchPool = rotated(pool(for: .lunch, from: candidates), by: varietySalt &+ 3)
        let dinnerPool = rotated(pool(for: .dinner, from: candidates), by: varietySalt &+ 7)

        var ranked: [(sources: [Recipe], scale: Double, score: Double)] = []

        for breakfast in breakfastPool {
            for lunch in lunchPool {
                for dinner in dinnerPool {
                    guard let bId = breakfast.catalogRecipeId,
                          let lId = lunch.catalogRecipeId,
                          let dId = dinner.catalogRecipeId
                    else { continue }
                    guard Set([bId, lId, dId]).count == 3 else { continue }

                    let base = macrosSum([breakfast, lunch, dinner])
                    guard base.calories > 0 else { continue }
                    let scale = naturalScale(baseCalories: base.calories, targetCalories: target.calories)
                    let scaled = scaleMacros(base, by: scale)
                    let score = fitness(actual: scaled, target: target, scale: scale)
                    ranked.append(([breakfast, lunch, dinner], scale, score))
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
                scale: pick.scale
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
        let base = macrosSum(picks)
        let scale = naturalScale(baseCalories: base.calories, targetCalories: target.calories)
        let types: [MealType] = [.breakfast, .lunch, .dinner]
        let items = zip(picks, types).compactMap { source, type -> PlannedItem? in
            guard let id = source.catalogRecipeId else { return nil }
            return PlannedItem(catalogRecipeId: id, source: source, mealType: type, scale: scale)
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
        scale: Double
    ) {
        for required in [MealType.breakfast, .lunch, .dinner] {
            guard !items.contains(where: { $0.mealType == required }) else { continue }
            guard let pick = pool(for: required, from: candidates).first(where: {
                guard let id = $0.catalogRecipeId else { return false }
                return !used.contains(id)
            }), let id = pick.catalogRecipeId else { continue }
            used.insert(id)
            items.append(
                PlannedItem(
                    catalogRecipeId: id,
                    source: pick,
                    mealType: required,
                    scale: scale
                )
            )
        }
    }

    private static func pool(for mealType: MealType, from candidates: [Recipe]) -> [Recipe] {
        let tagged = candidates.filter {
            $0.mealTypeTags.isEmpty || $0.mealTypeTags.contains(mealType)
        }
        let source = tagged.isEmpty ? candidates : tagged
        return Array(
            source
                .sorted { lhs, rhs in
                    let left = NutritionCalculator.nutritionPerServing(for: lhs)
                    let right = NutritionCalculator.nutritionPerServing(for: rhs)
                    let leftDensity = left.protein / max(left.calories, 1)
                    let rightDensity = right.protein / max(right.calories, 1)
                    if leftDensity != rightDensity {
                        return leftDensity > rightDensity
                    }
                    return left.calories > right.calories
                }
                .prefix(poolLimit)
        )
    }

    private static func macrosSum(_ recipes: [Recipe]) -> DailyNutrition {
        recipes.reduce(into: DailyNutrition.zero) { partial, recipe in
            let nutrition = NutritionCalculator.nutritionPerServing(for: recipe)
            partial.calories += nutrition.calories
            partial.protein += nutrition.protein
            partial.fat += nutrition.fat
            partial.carbs += nutrition.carbs
        }
    }

    private static func scaleMacros(_ nutrition: DailyNutrition, by factor: Double) -> DailyNutrition {
        DailyNutrition(
            calories: nutrition.calories * factor,
            protein: nutrition.protein * factor,
            fat: nutrition.fat * factor,
            carbs: nutrition.carbs * factor
        )
    }

    private static func clampedScale(_ scale: Double) -> Double {
        min(max(scale, 0.7), 1.35)
    }

    /// Keep 1.0 when already in band; otherwise only nudge to the nearest band edge.
    private static func naturalScale(baseCalories: Double, targetCalories: Double) -> Double {
        guard baseCalories > 0, targetCalories > 0 else { return 1 }
        let coverage = baseCalories / targetCalories
        if coverage >= softMinCoverage && coverage <= softMaxCoverage {
            return 1
        }
        if coverage < softMinCoverage {
            return clampedScale((targetCalories * softMinCoverage) / baseCalories)
        }
        return clampedScale((targetCalories * softMaxCoverage) / baseCalories)
    }

    private static func fitness(actual: DailyNutrition, target: DailyNutrition, scale: Double) -> Double {
        let ratios = [
            ratio(actual.calories, target.calories),
            ratio(actual.protein, target.protein),
            ratio(actual.fat, target.fat),
            ratio(actual.carbs, target.carbs),
        ]
        let minimum = ratios.min() ?? 0
        let maximum = ratios.max() ?? 0
        let naturalBonus = (1 - abs(scale - 1)) * 220

        if minimum >= softMinCoverage && maximum <= softMaxCoverage {
            return 2_000 + naturalBonus + (1 - abs(minimum - 1)) * 40
        }
        if minimum >= softMinCoverage {
            return 1_000 + naturalBonus - max(0, maximum - softMaxCoverage) * 180
        }
        return minimum * 100 + naturalBonus - max(0, maximum - softMaxCoverage) * 50
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

    private static func cloneRecipe(
        _ source: Recipe,
        factor: Double,
        in context: ModelContext
    ) -> Recipe {
        let clone = Recipe(
            name: source.name,
            catalogRecipeId: source.catalogRecipeId,
            servings: 1,
            imageData: source.imageData,
            sourceURL: source.sourceURL,
            sourceDescription: source.sourceDescription,
            steps: source.steps,
            stepsRichTextData: source.stepsRichTextData,
            cookTimeMinutes: source.cookTimeMinutes,
            communityLikeCount: source.communityLikeCount,
            mealTypeTags: source.mealTypeTags,
            caloriesPer100g: source.caloriesPer100g,
            proteinPer100g: source.proteinPer100g,
            fatPer100g: source.fatPer100g,
            carbsPer100g: source.carbsPer100g
        )
        context.insert(clone)

        let ingredients = source.ingredients.map { ingredient in
            Ingredient(
                name: ingredient.name,
                quantity: ingredient.quantity * factor,
                unit: ingredient.unit,
                category: ingredient.category,
                recipe: clone,
                foodProduct: ingredient.foodProduct
            )
        }
        for ingredient in ingredients {
            context.insert(ingredient)
        }
        clone.ingredients = ingredients
        clone.recalculateNutrition()
        return clone
    }
}
