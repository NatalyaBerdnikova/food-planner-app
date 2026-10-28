import Foundation
import Observation
import SwiftData

enum WeekPlanGenerationState: Equatable {
    case idle
    case loading(WeekPlanGenerationStage)
    case ready
    case failed(String)
}

struct WeekPlanGenerationPresentation: Identifiable {
    let id = UUID()
}

struct GenerateWeekPlanPresentation: Identifiable {
    let id = UUID()
}

@MainActor
@Observable
final class WeekPlanGenerationCoordinator {
    var state: WeekPlanGenerationState = .idle
    var progressPresentation: WeekPlanGenerationPresentation?
    var composePresentation: GenerateWeekPlanPresentation?

    private var generationTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    private var replaceExisting = true
    private var targetWeekStart: Date?

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func presentCompose(forWeekStarting weekStart: Date) {
        targetWeekStart = Calendar.current.startOfWeek(for: weekStart)
        composePresentation = GenerateWeekPlanPresentation()
    }

    func dismissCompose() {
        composePresentation = nil
    }

    func startGeneration(replaceExisting: Bool = true, forWeekStarting weekStart: Date? = nil) {
        guard let context = modelContext else { return }

        generationTask?.cancel()
        self.replaceExisting = replaceExisting
        if let weekStart {
            targetWeekStart = Calendar.current.startOfWeek(for: weekStart)
        }
        composePresentation = nil
        state = .loading(.pickingRecipes)
        progressPresentation = WeekPlanGenerationPresentation()
        AppAnalytics.logPlanGenerateStart(replaceExisting: replaceExisting)

        generationTask = Task {
            await performGeneration(in: context, replaceExisting: replaceExisting)
        }
    }

    func startPendingGenerationIfNeeded() {
        guard MealPlanGenerationPending.needsGeneration else { return }
        startGeneration(
            replaceExisting: false,
            forWeekStarting: Calendar.current.startOfWeek(for: .now)
        )
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        state = .idle
        progressPresentation = nil
    }

    func dismissError() {
        state = .idle
        progressPresentation = nil
    }

    func dismissSuccess() {
        state = .idle
        progressPresentation = nil
        MealPlanGenerationPending.clear()
    }

    private func performGeneration(in context: ModelContext, replaceExisting: Bool) async {
        let settings = AppSettingsService.settings(in: context)
        let weekPlans = (try? context.fetch(FetchDescriptor<WeekPlan>())) ?? []
        let weekStart = targetWeekStart ?? Calendar.current.startOfWeek(for: .now)
        let weekPlan = WeekPlanService.weekPlan(
            forWeekStarting: weekStart,
            from: weekPlans,
            in: context
        )
        let candidates = ((try? context.fetch(FetchDescriptor<Recipe>())) ?? []).filter {
            $0.isCatalogRecipe && $0.isVisibleInApp
        }

        let pinnedToday: MealPlanGenerator.DayBlueprint? = {
            guard !replaceExisting,
                  let snapshot = MealPlanGenerationPending.previewSnapshot
            else { return nil }
            return MealPlanGenerator.blueprint(from: snapshot, candidates: candidates)
        }()

        await MealPlanGenerator.generateWeek(
            weekPlan: weekPlan,
            matching: settings.targetNutrition,
            micronutrientFocus: settings.profileMicronutrientFocus,
            pinnedToday: pinnedToday,
            replaceExisting: replaceExisting,
            in: context,
            onStage: { [weak self] stage in
                self?.state = .loading(stage)
            }
        )
        guard !Task.isCancelled else { return }
        MealPlanGenerationPending.clear()
        let mealsCount = weekPlan.dayPlans.reduce(0) { $0 + $1.meals.count }
        let daysFilled = weekPlan.dayPlans.filter { !$0.meals.isEmpty }.count
        AppAnalytics.logPlanGenerateSuccess(mealsCount: mealsCount, daysFilled: daysFilled)
        state = .ready
    }
}
