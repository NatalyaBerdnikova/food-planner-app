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
    ]

    static var container: ModelContainer {
        let schema = Schema(modelTypes)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
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
