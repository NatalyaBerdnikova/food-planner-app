import Foundation

struct MealPlanDaySnapshot: Codable, Equatable {
    struct Slot: Codable, Equatable {
        var mealTypeRaw: String
        var catalogRecipeId: String
        var scale: Double

        var mealType: MealType? { MealType(rawValue: mealTypeRaw) }
    }

    var slots: [Slot]
    var createdAt: Date
}

enum MealPlanGenerationPending {
    private static let needsKey = "mealPlan.needsGeneration"
    private static let snapshotKey = "mealPlan.previewSnapshot"

    static var needsGeneration: Bool {
        get { UserDefaults.standard.bool(forKey: needsKey) }
        set { UserDefaults.standard.set(newValue, forKey: needsKey) }
    }

    static var previewSnapshot: MealPlanDaySnapshot? {
        get {
            guard let data = UserDefaults.standard.data(forKey: snapshotKey) else { return nil }
            return try? JSONDecoder().decode(MealPlanDaySnapshot.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: snapshotKey)
            } else {
                UserDefaults.standard.removeObject(forKey: snapshotKey)
            }
        }
    }

    static func markNeedsGeneration() {
        needsGeneration = true
    }

    static func clear() {
        needsGeneration = false
        previewSnapshot = nil
    }
}
