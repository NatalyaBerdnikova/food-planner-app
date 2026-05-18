import Foundation
import SwiftData

enum FoodCatalogSeeder {
    struct ProductSeed {
        let key: String
        let category: IngredientCategory
        let pieceGrams: Double
        let calories: Double
        let protein: Double
        let fat: Double
        let carbs: Double
        let fiber: Double
        let sugar: Double
        let saturatedFat: Double
        let sodium: Double
        let potassium: Double
        let calcium: Double
        let iron: Double
        let magnesium: Double
        let zinc: Double
        let vitaminC: Double
        let vitaminD: Double
        let vitaminB12: Double
        let folate: Double
    }

    static let catalog: [ProductSeed] = [
        .init(key: "chicken_breast", category: .meat, pieceGrams: 100, calories: 165, protein: 31, fat: 3.6, carbs: 0, fiber: 0, sugar: 0, saturatedFat: 1, sodium: 74, potassium: 256, calcium: 15, iron: 1, magnesium: 29, zinc: 1, vitaminC: 0, vitaminD: 0.1, vitaminB12: 0.3, folate: 4),
        .init(key: "beef", category: .meat, pieceGrams: 100, calories: 250, protein: 26, fat: 17, carbs: 0, fiber: 0, sugar: 0, saturatedFat: 7, sodium: 72, potassium: 318, calcium: 18, iron: 2.6, magnesium: 21, zinc: 6, vitaminC: 0, vitaminD: 0.1, vitaminB12: 2.6, folate: 9),
        .init(key: "salmon", category: .fish, pieceGrams: 100, calories: 208, protein: 20, fat: 13, carbs: 0, fiber: 0, sugar: 0, saturatedFat: 3, sodium: 59, potassium: 363, calcium: 9, iron: 0.3, magnesium: 27, zinc: 0.6, vitaminC: 0, vitaminD: 11, vitaminB12: 3.2, folate: 25),
        .init(key: "egg", category: .dairy, pieceGrams: 50, calories: 155, protein: 13, fat: 11, carbs: 1.1, fiber: 0, sugar: 1.1, saturatedFat: 3.3, sodium: 124, potassium: 126, calcium: 50, iron: 1.2, magnesium: 10, zinc: 1, vitaminC: 0, vitaminD: 2, vitaminB12: 0.9, folate: 44),
        .init(key: "milk", category: .dairy, pieceGrams: 100, calories: 42, protein: 3.4, fat: 1, carbs: 5, fiber: 0, sugar: 5, saturatedFat: 0.6, sodium: 44, potassium: 150, calcium: 125, iron: 0, magnesium: 11, zinc: 0.4, vitaminC: 0, vitaminD: 1.2, vitaminB12: 0.5, folate: 5),
        .init(key: "yogurt", category: .dairy, pieceGrams: 100, calories: 59, protein: 10, fat: 0.4, carbs: 3.6, fiber: 0, sugar: 3.2, saturatedFat: 0.1, sodium: 36, potassium: 141, calcium: 110, iron: 0.1, magnesium: 11, zinc: 0.5, vitaminC: 0, vitaminD: 0, vitaminB12: 0.4, folate: 7),
        .init(key: "cheese", category: .dairy, pieceGrams: 30, calories: 402, protein: 25, fat: 33, carbs: 1.3, fiber: 0, sugar: 0.5, saturatedFat: 21, sodium: 621, potassium: 98, calcium: 721, iron: 0.7, magnesium: 28, zinc: 3.1, vitaminC: 0, vitaminD: 0.6, vitaminB12: 1.1, folate: 18),
        .init(key: "oatmeal", category: .grains, pieceGrams: 100, calories: 389, protein: 17, fat: 7, carbs: 66, fiber: 11, sugar: 1, saturatedFat: 1.2, sodium: 2, potassium: 429, calcium: 54, iron: 4.7, magnesium: 177, zinc: 4, vitaminC: 0, vitaminD: 0, vitaminB12: 0, folate: 56),
        .init(key: "rice", category: .grains, pieceGrams: 100, calories: 130, protein: 2.7, fat: 0.3, carbs: 28, fiber: 0.4, sugar: 0.1, saturatedFat: 0.1, sodium: 1, potassium: 35, calcium: 10, iron: 0.2, magnesium: 12, zinc: 0.5, vitaminC: 0, vitaminD: 0, vitaminB12: 0, folate: 8),
        .init(key: "pasta", category: .grains, pieceGrams: 100, calories: 131, protein: 5, fat: 1.1, carbs: 25, fiber: 1.8, sugar: 0.6, saturatedFat: 0.2, sodium: 1, potassium: 44, calcium: 7, iron: 0.9, magnesium: 18, zinc: 0.5, vitaminC: 0, vitaminD: 0, vitaminB12: 0, folate: 18),
        .init(key: "bread", category: .grains, pieceGrams: 30, calories: 265, protein: 9, fat: 3.2, carbs: 49, fiber: 2.7, sugar: 5, saturatedFat: 0.7, sodium: 491, potassium: 115, calcium: 151, iron: 3.6, magnesium: 25, zinc: 0.7, vitaminC: 0, vitaminD: 0, vitaminB12: 0, folate: 111),
        .init(key: "potato", category: .vegetables, pieceGrams: 150, calories: 77, protein: 2, fat: 0.1, carbs: 17, fiber: 2.2, sugar: 0.8, saturatedFat: 0, sodium: 6, potassium: 425, calcium: 12, iron: 0.8, magnesium: 23, zinc: 0.3, vitaminC: 19.7, vitaminD: 0, vitaminB12: 0, folate: 15),
        .init(key: "tomato", category: .vegetables, pieceGrams: 120, calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9, fiber: 1.2, sugar: 2.6, saturatedFat: 0, sodium: 5, potassium: 237, calcium: 10, iron: 0.3, magnesium: 11, zinc: 0.2, vitaminC: 13.7, vitaminD: 0, vitaminB12: 0, folate: 15),
        .init(key: "cucumber", category: .vegetables, pieceGrams: 100, calories: 15, protein: 0.7, fat: 0.1, carbs: 3.6, fiber: 0.5, sugar: 1.7, saturatedFat: 0, sodium: 2, potassium: 147, calcium: 16, iron: 0.3, magnesium: 13, zinc: 0.2, vitaminC: 2.8, vitaminD: 0, vitaminB12: 0, folate: 7),
        .init(key: "carrot", category: .vegetables, pieceGrams: 60, calories: 41, protein: 0.9, fat: 0.2, carbs: 10, fiber: 2.8, sugar: 4.7, saturatedFat: 0, sodium: 69, potassium: 320, calcium: 33, iron: 0.3, magnesium: 12, zinc: 0.2, vitaminC: 5.9, vitaminD: 0, vitaminB12: 0, folate: 19),
        .init(key: "onion", category: .vegetables, pieceGrams: 110, calories: 40, protein: 1.1, fat: 0.1, carbs: 9.3, fiber: 1.7, sugar: 4.2, saturatedFat: 0, sodium: 4, potassium: 146, calcium: 23, iron: 0.2, magnesium: 10, zinc: 0.2, vitaminC: 7.4, vitaminD: 0, vitaminB12: 0, folate: 19),
        .init(key: "broccoli", category: .vegetables, pieceGrams: 100, calories: 34, protein: 2.8, fat: 0.4, carbs: 7, fiber: 2.6, sugar: 1.7, saturatedFat: 0, sodium: 33, potassium: 316, calcium: 47, iron: 0.7, magnesium: 21, zinc: 0.4, vitaminC: 89.2, vitaminD: 0, vitaminB12: 0, folate: 63),
        .init(key: "spinach", category: .vegetables, pieceGrams: 100, calories: 23, protein: 2.9, fat: 0.4, carbs: 3.6, fiber: 2.2, sugar: 0.4, saturatedFat: 0.1, sodium: 79, potassium: 558, calcium: 99, iron: 2.7, magnesium: 79, zinc: 0.5, vitaminC: 28.1, vitaminD: 0, vitaminB12: 0, folate: 194),
        .init(key: "banana", category: .fruits, pieceGrams: 120, calories: 89, protein: 1.1, fat: 0.3, carbs: 23, fiber: 2.6, sugar: 12, saturatedFat: 0.1, sodium: 1, potassium: 358, calcium: 5, iron: 0.3, magnesium: 27, zinc: 0.2, vitaminC: 8.7, vitaminD: 0, vitaminB12: 0, folate: 20),
        .init(key: "apple", category: .fruits, pieceGrams: 180, calories: 52, protein: 0.3, fat: 0.2, carbs: 14, fiber: 2.4, sugar: 10, saturatedFat: 0, sodium: 1, potassium: 107, calcium: 6, iron: 0.1, magnesium: 5, zinc: 0, vitaminC: 4.6, vitaminD: 0, vitaminB12: 0, folate: 3),
        .init(key: "olive_oil", category: .other, pieceGrams: 100, calories: 884, protein: 0, fat: 100, carbs: 0, fiber: 0, sugar: 0, saturatedFat: 14, sodium: 2, potassium: 1, calcium: 1, iron: 0.6, magnesium: 0, zinc: 0, vitaminC: 0, vitaminD: 0, vitaminB12: 0, folate: 0),
        .init(key: "butter", category: .dairy, pieceGrams: 10, calories: 717, protein: 0.9, fat: 81, carbs: 0.1, fiber: 0, sugar: 0.1, saturatedFat: 51, sodium: 11, potassium: 24, calcium: 24, iron: 0, magnesium: 2, zinc: 0.1, vitaminC: 0, vitaminD: 1.5, vitaminB12: 0.2, folate: 3),
        .init(key: "sugar", category: .other, pieceGrams: 100, calories: 387, protein: 0, fat: 0, carbs: 100, fiber: 0, sugar: 100, saturatedFat: 0, sodium: 1, potassium: 2, calcium: 1, iron: 0.1, magnesium: 0, zinc: 0, vitaminC: 0, vitaminD: 0, vitaminB12: 0, folate: 0),
        .init(key: "honey", category: .other, pieceGrams: 100, calories: 304, protein: 0.3, fat: 0, carbs: 82, fiber: 0.2, sugar: 82, saturatedFat: 0, sodium: 4, potassium: 52, calcium: 6, iron: 0.4, magnesium: 2, zinc: 0.2, vitaminC: 0.5, vitaminD: 0, vitaminB12: 0, folate: 2),
        .init(key: "lentils", category: .grains, pieceGrams: 100, calories: 116, protein: 9, fat: 0.4, carbs: 20, fiber: 8, sugar: 1.8, saturatedFat: 0.1, sodium: 2, potassium: 369, calcium: 19, iron: 3.3, magnesium: 36, zinc: 1.3, vitaminC: 1.5, vitaminD: 0, vitaminB12: 0, folate: 181),
        .init(key: "beans", category: .grains, pieceGrams: 100, calories: 127, protein: 8.7, fat: 0.5, carbs: 23, fiber: 6.4, sugar: 0.3, saturatedFat: 0.1, sodium: 2, potassium: 405, calcium: 28, iron: 2.1, magnesium: 45, zinc: 1, vitaminC: 1.2, vitaminD: 0, vitaminB12: 0, folate: 149),
        .init(key: "almonds", category: .other, pieceGrams: 100, calories: 579, protein: 21, fat: 50, carbs: 22, fiber: 12, sugar: 4.4, saturatedFat: 3.8, sodium: 1, potassium: 733, calcium: 269, iron: 3.7, magnesium: 270, zinc: 3.1, vitaminC: 0, vitaminD: 0, vitaminB12: 0, folate: 44),
        .init(key: "garlic", category: .vegetables, pieceGrams: 3, calories: 149, protein: 6.4, fat: 0.5, carbs: 33, fiber: 2.1, sugar: 1, saturatedFat: 0.1, sodium: 17, potassium: 401, calcium: 181, iron: 1.7, magnesium: 25, zinc: 1.2, vitaminC: 31.2, vitaminD: 0, vitaminB12: 0, folate: 3),
        .init(key: "lemon", category: .fruits, pieceGrams: 60, calories: 29, protein: 1.1, fat: 0.3, carbs: 9, fiber: 2.8, sugar: 2.5, saturatedFat: 0, sodium: 2, potassium: 138, calcium: 26, iron: 0.6, magnesium: 8, zinc: 0.1, vitaminC: 53, vitaminD: 0, vitaminB12: 0, folate: 11),
        .init(key: "avocado", category: .fruits, pieceGrams: 150, calories: 160, protein: 2, fat: 15, carbs: 9, fiber: 7, sugar: 0.7, saturatedFat: 2.1, sodium: 7, potassium: 485, calcium: 12, iron: 0.6, magnesium: 29, zinc: 0.6, vitaminC: 10, vitaminD: 0, vitaminB12: 0, folate: 81),
        .init(key: "bell_pepper", category: .vegetables, pieceGrams: 120, calories: 31, protein: 1, fat: 0.3, carbs: 6, fiber: 2.1, sugar: 4.2, saturatedFat: 0, sodium: 4, potassium: 211, calcium: 7, iron: 0.4, magnesium: 12, zinc: 0.3, vitaminC: 127.7, vitaminD: 0, vitaminB12: 0, folate: 46),
        .init(key: "turkey", category: .meat, pieceGrams: 100, calories: 135, protein: 30, fat: 1, carbs: 0, fiber: 0, sugar: 0, saturatedFat: 0.3, sodium: 54, potassium: 249, calcium: 14, iron: 1.4, magnesium: 30, zinc: 2.5, vitaminC: 0, vitaminD: 0.2, vitaminB12: 1.2, folate: 7),
    ]

    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<FoodProduct>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for seed in catalog {
            let product = FoodProduct(
                catalogKey: seed.key,
                category: seed.category,
                defaultPieceWeightGrams: seed.pieceGrams,
                caloriesPer100g: seed.calories,
                proteinPer100g: seed.protein,
                fatPer100g: seed.fat,
                carbsPer100g: seed.carbs,
                fiberPer100g: seed.fiber,
                sugarPer100g: seed.sugar,
                saturatedFatPer100g: seed.saturatedFat,
                sodiumPer100g: seed.sodium,
                potassiumPer100g: seed.potassium,
                calciumPer100g: seed.calcium,
                ironPer100g: seed.iron,
                magnesiumPer100g: seed.magnesium,
                zincPer100g: seed.zinc,
                vitaminCPer100g: seed.vitaminC,
                vitaminDPer100g: seed.vitaminD,
                vitaminB12Per100g: seed.vitaminB12,
                folatePer100g: seed.folate
            )
            context.insert(product)
        }
    }

    @MainActor
    static func product(forKey key: String, in context: ModelContext) -> FoodProduct? {
        var descriptor = FetchDescriptor<FoodProduct>(
            predicate: #Predicate { $0.catalogKey == key }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
