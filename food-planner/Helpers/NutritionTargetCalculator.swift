import Foundation

enum BiologicalSex: String, CaseIterable, Identifiable {
    case female
    case male

    var id: String { rawValue }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive

    var id: String { rawValue }

    /// Множитель активности для TDEE.
    var factor: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .active: 1.725
        case .veryActive: 1.9
        }
    }

    var localizationKey: String {
        switch self {
        case .sedentary: "calculator.activity.sedentary"
        case .light: "calculator.activity.light"
        case .moderate: "calculator.activity.moderate"
        case .active: "calculator.activity.active"
        case .veryActive: "calculator.activity.veryActive"
        }
    }
}

struct NutritionTargetInput {
    var sex: BiologicalSex
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var targetWeightKg: Double
    var activityLevel: ActivityLevel
    /// Белки, г на 1 кг желаемого веса (1…3).
    var proteinGramsPerKg: Double
    /// Жиры, г на 1 кг желаемого веса (0.8…1.5).
    var fatGramsPerKg: Double
}

enum NutritionTargetCalculator {
    private static let kcalPerGramProtein = 4.0
    private static let kcalPerGramFat = 9.0
    private static let kcalPerGramCarbs = 4.0

    static let proteinGramsPerKgRange = 1.0...3.0
    static let fatGramsPerKgRange = 0.8...1.5

    /// BMR по формуле Миффлина — Сан Жеора.
    static func basalMetabolicRate(input: NutritionTargetInput) -> Double {
        let base = 10 * input.weightKg + 6.25 * input.heightCm - 5 * Double(input.age)
        switch input.sex {
        case .male: return base + 5
        case .female: return base - 161
        }
    }

    /// Суточная норма калорий (TDEE).
    static func totalDailyEnergy(input: NutritionTargetInput) -> Double {
        basalMetabolicRate(input: input) * input.activityLevel.factor
    }

    static func calculate(input: NutritionTargetInput) -> DailyNutrition? {
        guard input.age > 0,
              input.heightCm > 0,
              input.weightKg > 0,
              input.targetWeightKg > 0,
              proteinGramsPerKgRange.contains(input.proteinGramsPerKg),
              fatGramsPerKgRange.contains(input.fatGramsPerKg) else {
            return nil
        }

        let calories = totalDailyEnergy(input: input).rounded()

        let protein = (input.proteinGramsPerKg * input.targetWeightKg).rounded(toPlaces: 1)
        let fat = (input.fatGramsPerKg * input.targetWeightKg).rounded(toPlaces: 1)

        let proteinKcal = protein * kcalPerGramProtein
        let fatKcal = fat * kcalPerGramFat
        let remainingKcal = max(0, calories - proteinKcal - fatKcal)
        let carbs = (remainingKcal / kcalPerGramCarbs).rounded(toPlaces: 1)

        return DailyNutrition(
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs
        )
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
