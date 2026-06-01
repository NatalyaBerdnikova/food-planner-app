import SwiftData

enum FoodPlannerSchema {
    static let modelTypes: [any PersistentModel.Type] = [
        FoodProduct.self,
        Recipe.self,
        Ingredient.self,
        Meal.self,
        DayPlan.self,
        WeekPlan.self,
        ShoppingItem.self,
        AppSettings.self,
    ]

    static var container: ModelContainer {
        makeContainer(recoveryAttempted: false)
    }

    private static func makeContainer(recoveryAttempted: Bool) -> ModelContainer {
        let schema = Schema(modelTypes)
        let configuration = ModelConfiguration(
            schema: schema,
            url: LocalPersistence.storeURL
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            guard !recoveryAttempted else {
                fatalError("Не удалось создать ModelContainer: \(error)")
            }
            #if DEBUG
            print("SwiftData: сброс локальной БД после ошибки загрузки: \(error)")
            #endif
            LocalPersistence.removeStore()
            return makeContainer(recoveryAttempted: true)
        }
    }

    @MainActor
    static var previewContainer: ModelContainer = {
        let container = try! ModelContainer(
            for: Schema(modelTypes),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        PreviewSampleData.populate(in: container)
        return container
    }()
}
