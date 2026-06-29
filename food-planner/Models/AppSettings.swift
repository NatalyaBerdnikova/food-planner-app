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

    /// Сериализованные `catalogRecipeId` (разделитель Unit Separator).
    var favoriteCatalogRecipeIdsStorage: String = ""

    var isPro: Bool = false
    var isFree: Bool = false

    var hasFullAccess: Bool { isPro || isFree }

    init(
        singletonKey: String = "main",
        targetCalories: Double = 2000,
        targetProtein: Double = 90,
        targetFat: Double = 70,
        targetCarbs: Double = 250,
        activeWeekPlan: WeekPlan? = nil,
        favoriteCatalogRecipeIds: [String] = []
    ) {
        self.singletonKey = singletonKey
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetFat = targetFat
        self.targetCarbs = targetCarbs
        self.activeWeekPlan = activeWeekPlan
        self.favoriteCatalogRecipeIds = favoriteCatalogRecipeIds
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
    private static let favoritesSeparator = "\u{1F}"

    var favoriteCatalogRecipeIds: [String] {
        get {
            guard !favoriteCatalogRecipeIdsStorage.isEmpty else { return [] }
            return favoriteCatalogRecipeIdsStorage
                .components(separatedBy: Self.favoritesSeparator)
                .filter { !$0.isEmpty }
        }
        set {
            favoriteCatalogRecipeIdsStorage = newValue.joined(separator: Self.favoritesSeparator)
        }
    }
}
