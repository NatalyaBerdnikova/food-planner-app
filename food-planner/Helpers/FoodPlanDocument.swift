import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum FoodPlanUTType {
    static let identifier = "com.mikhail-chugaev.food-planner.foodplan"
    static let fileExtension = "foodplan"

    static var utType: UTType {
        UTType(exportedAs: identifier) ?? UTType(filenameExtension: fileExtension) ?? .data
    }
}

struct FoodPlanDocument: Codable, Equatable {
    var formatVersion: Int
    var createdAt: Date
    var appVersion: String?
    var targets: FoodPlanTargetsDTO?
    var days: [FoodPlanDayDTO]

    static let currentFormatVersion = 1

    var mealCount: Int {
        days.reduce(0) { $0 + $1.meals.count }
    }

    var filledDayCount: Int {
        days.filter { !$0.meals.isEmpty }.count
    }
}

struct FoodPlanTargetsDTO: Codable, Equatable {
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
}

struct FoodPlanDayDTO: Codable, Equatable {
    /// 0…6 from the exported week start (Monday-based via Calendar.startOfWeek).
    var dayOffset: Int
    var meals: [FoodPlanMealDTO]
}

struct FoodPlanMealDTO: Codable, Equatable {
    var mealType: String
    var recipe: FoodPlanRecipeDTO
}

struct FoodPlanRecipeDTO: Codable, Equatable {
    var catalogRecipeId: String?
    var name: String
    var servings: Int
    var steps: [String]
    var cookTimeMinutes: Int
    var mealTypeTags: [String]
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var fatPer100g: Double
    var carbsPer100g: Double
    var imageJPEGBase64: String?
    var ingredients: [FoodPlanIngredientDTO]
}

struct FoodPlanIngredientDTO: Codable, Equatable {
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var foodProductCatalogKey: String?
}

enum WeekPlanImportMode: String, CaseIterable, Identifiable {
    case replaceWeek
    case fillEmptyDaysOnly

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .replaceWeek: "weekPlan.import.mode.replace"
        case .fillEmptyDaysOnly: "weekPlan.import.mode.fillEmpty"
        }
    }

    var subtitleKey: LocalizedStringKey {
        switch self {
        case .replaceWeek: "weekPlan.import.mode.replace.subtitle"
        case .fillEmptyDaysOnly: "weekPlan.import.mode.fillEmpty.subtitle"
        }
    }
}
