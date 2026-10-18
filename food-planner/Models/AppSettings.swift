import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var singletonKey: String

    var targetCalories: Double
    var targetProtein: Double
    var targetFat: Double
    var targetCarbs: Double

    var activeWeekPlan: WeekPlan?

    var favoriteCatalogRecipeIdsStorage: String = ""
    var hiddenCatalogRecipeIdsStorage: String = ""

    var isPro: Bool = false
    var isFree: Bool = false

    var hasCompletedOnboarding: Bool = false
    var profileSexRaw: String = BiologicalSex.female.rawValue
    var profileAge: Int = 30
    var profileHeightCm: Double = 165
    var profileWeightKg: Double = 65
    var profileTargetWeightKg: Double = 65
    var profileActivityRaw: String = ActivityLevel.moderate.rawValue
    var profileGoalRaw: String = NutritionGoal.maintain.rawValue
    var profileDietFlagsStorage: String = ""
    var profileMicronutrientFocusStorage: String = ""
    var profileRecipeSourceRaw: String = RecipeSourceHabit.instagram.rawValue

    var hasFullAccess: Bool { isPro || isFree }

    init(
        singletonKey: String = "main",
        targetCalories: Double = 2000,
        targetProtein: Double = 90,
        targetFat: Double = 70,
        targetCarbs: Double = 250,
        activeWeekPlan: WeekPlan? = nil,
        favoriteCatalogRecipeIds: [String] = [],
        hiddenCatalogRecipeIds: [String] = []
    ) {
        self.singletonKey = singletonKey
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetFat = targetFat
        self.targetCarbs = targetCarbs
        self.activeWeekPlan = activeWeekPlan
        self.favoriteCatalogRecipeIds = favoriteCatalogRecipeIds
        self.hiddenCatalogRecipeIds = hiddenCatalogRecipeIds
    }

    var targetNutrition: DailyNutrition {
        DailyNutrition(
            calories: targetCalories,
            protein: targetProtein,
            fat: targetFat,
            carbs: targetCarbs
        )
    }
}

extension AppSettings {
    private static let listSeparator = "\u{1F}"

    var favoriteCatalogRecipeIds: [String] {
        get {
            guard !favoriteCatalogRecipeIdsStorage.isEmpty else { return [] }
            return favoriteCatalogRecipeIdsStorage
                .components(separatedBy: Self.listSeparator)
                .filter { !$0.isEmpty }
        }
        set {
            favoriteCatalogRecipeIdsStorage = newValue.joined(separator: Self.listSeparator)
        }
    }

    var hiddenCatalogRecipeIds: [String] {
        get {
            guard !hiddenCatalogRecipeIdsStorage.isEmpty else { return [] }
            return hiddenCatalogRecipeIdsStorage
                .components(separatedBy: Self.listSeparator)
                .filter { !$0.isEmpty }
        }
        set {
            hiddenCatalogRecipeIdsStorage = newValue.joined(separator: Self.listSeparator)
        }
    }

    var profileSex: BiologicalSex {
        get { BiologicalSex(rawValue: profileSexRaw) ?? .female }
        set { profileSexRaw = newValue.rawValue }
    }

    var profileActivity: ActivityLevel {
        get { ActivityLevel(rawValue: profileActivityRaw) ?? .moderate }
        set { profileActivityRaw = newValue.rawValue }
    }

    var profileGoal: NutritionGoal {
        get { NutritionGoal(rawValue: profileGoalRaw) ?? .maintain }
        set { profileGoalRaw = newValue.rawValue }
    }

    var profileRecipeSource: RecipeSourceHabit {
        get { RecipeSourceHabit(rawValue: profileRecipeSourceRaw) ?? .instagram }
        set { profileRecipeSourceRaw = newValue.rawValue }
    }

    var profileDietPreferences: Set<DietPreference> {
        get {
            Set(
                profileDietFlagsStorage
                    .components(separatedBy: Self.listSeparator)
                    .compactMap(DietPreference.init(rawValue:))
            )
        }
        set {
            profileDietFlagsStorage = newValue.map(\.rawValue).sorted().joined(separator: Self.listSeparator)
        }
    }

    var profileMicronutrientFocus: [MicronutrientKind] {
        get {
            profileMicronutrientFocusStorage
                .components(separatedBy: Self.listSeparator)
                .compactMap(MicronutrientKind.init(rawValue:))
        }
        set {
            profileMicronutrientFocusStorage = newValue.map(\.rawValue).joined(separator: Self.listSeparator)
        }
    }

    func apply(onboarding draft: OnboardingDraft, nutrition: DailyNutrition) {
        hasCompletedOnboarding = true
        profileGoal = draft.goal
        profileSex = draft.sex
        profileAge = draft.age
        profileHeightCm = draft.heightCm
        profileWeightKg = draft.weightKg
        profileTargetWeightKg = draft.targetWeightKg
        profileActivity = draft.activity
        profileDietPreferences = draft.dietPreferences
        profileMicronutrientFocus = Array(draft.micronutrientFocus)
        profileRecipeSource = draft.recipeSource
        apply(targets: nutrition)
    }

    func apply(calculatorInput input: NutritionTargetInput, nutrition: DailyNutrition) {
        profileSex = input.sex
        profileAge = input.age
        profileHeightCm = input.heightCm
        profileWeightKg = input.weightKg
        profileTargetWeightKg = input.targetWeightKg
        profileActivity = input.activityLevel
        apply(targets: nutrition)
    }

    func apply(targets nutrition: DailyNutrition) {
        targetCalories = nutrition.calories
        targetProtein = nutrition.protein
        targetFat = nutrition.fat
        targetCarbs = nutrition.carbs
    }
}
