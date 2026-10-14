import Foundation

enum NutritionGoal: String, CaseIterable, Identifiable {
    case lose
    case maintain
    case gain

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .lose: "onboarding.goal.lose"
        case .maintain: "onboarding.goal.maintain"
        case .gain: "onboarding.goal.gain"
        }
    }

    var proteinGramsPerKg: Double {
        switch self {
        case .lose: 2.0
        case .maintain: 1.6
        case .gain: 1.8
        }
    }

    var fatGramsPerKg: Double {
        switch self {
        case .lose: 0.9
        case .maintain: 1.0
        case .gain: 1.1
        }
    }
}

enum DietPreference: String, CaseIterable, Identifiable {
    case none
    case vegetarian
    case vegan
    case glutenFree
    case dairyFree
    case highProtein

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .none: "onboarding.diet.none"
        case .vegetarian: "onboarding.diet.vegetarian"
        case .vegan: "onboarding.diet.vegan"
        case .glutenFree: "onboarding.diet.glutenFree"
        case .dairyFree: "onboarding.diet.dairyFree"
        case .highProtein: "onboarding.diet.highProtein"
        }
    }
}

enum RecipeSourceHabit: String, CaseIterable, Identifiable {
    case instagram
    case tiktok
    case blogs
    case books
    case improvisation

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .instagram: "onboarding.habits.instagram"
        case .tiktok: "onboarding.habits.tiktok"
        case .blogs: "onboarding.habits.blogs"
        case .books: "onboarding.habits.books"
        case .improvisation: "onboarding.habits.improvisation"
        }
    }
}

struct OnboardingDraft {
    var goal: NutritionGoal = .maintain
    var sex: BiologicalSex = .female
    var age: Int = 30
    var heightCm: Double = 165
    var weightKg: Double = 65
    var targetWeightKg: Double = 65
    var activity: ActivityLevel = .moderate
    var dietPreferences: Set<DietPreference> = []
    var micronutrientFocus: Set<MicronutrientKind> = []
    var recipeSource: RecipeSourceHabit = .instagram

    var nutritionInput: NutritionTargetInput {
        NutritionTargetInput(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            targetWeightKg: targetWeightKg,
            activityLevel: activity,
            proteinGramsPerKg: goal.proteinGramsPerKg,
            fatGramsPerKg: goal.fatGramsPerKg
        )
    }

    func calculatedNutrition() -> DailyNutrition? {
        NutritionTargetCalculator.calculate(input: nutritionInput)
    }
}
