import Foundation
import SwiftData

enum FoodCatalogSeeder {
    struct Micro {
        var fiber = 0.0
        var d3 = 0.0
        var ca = 0.0
        var mg = 0.0
        var zn = 0.0
        var k = 0.0
        var c = 0.0
        var e = 0.0
        var a = 0.0
        var b6 = 0.0
        var b9 = 0.0
        var b12 = 0.0
        var se = 0.0
        var cr = 0.0
        var fe = 0.0
        var kali = 0.0
        var i = 0.0
    }

    struct ProductSeed {
        let key: String
        let category: IngredientCategory
        let pieceGrams: Double
        let calories: Double
        let protein: Double
        let fat: Double
        let carbs: Double
        let micro: Micro
    }

  // swiftlint:disable line_length
    static let catalog: [ProductSeed] = [
        .init(key: "chicken_breast", category: .meat, pieceGrams: 100, calories: 165, protein: 31, fat: 3.6, carbs: 0, micro: .init(d3: 0.1, ca: 15, mg: 29, zn: 1, b6: 0.6, b9: 4, b12: 0.3, se: 22, fe: 1, kali: 256, i: 7)),
        .init(key: "beef", category: .meat, pieceGrams: 100, calories: 250, protein: 26, fat: 17, carbs: 0, micro: .init(d3: 0.1, ca: 18, mg: 21, zn: 6, b6: 0.4, b9: 9, b12: 2.6, se: 20, cr: 2, fe: 2.6, kali: 318, i: 8)),
        .init(key: "salmon", category: .fish, pieceGrams: 100, calories: 208, protein: 20, fat: 13, carbs: 0, micro: .init(d3: 11, ca: 9, mg: 27, zn: 0.6, e: 1.1, a: 12, b6: 0.6, b9: 25, b12: 3.2, se: 37, fe: 0.3, kali: 363, i: 34)),
        .init(key: "egg", category: .dairy, pieceGrams: 50, calories: 155, protein: 13, fat: 11, carbs: 1.1, micro: .init(d3: 2, ca: 50, mg: 10, zn: 1, k: 0.3, e: 1, a: 160, b6: 0.1, b9: 44, b12: 0.9, se: 31, fe: 1.2, kali: 126, i: 24)),
        .init(key: "milk", category: .dairy, pieceGrams: 100, calories: 42, protein: 3.4, fat: 1, carbs: 5, micro: .init(d3: 1.2, ca: 125, mg: 11, zn: 0.4, a: 14, b6: 0.04, b9: 5, b12: 0.5, se: 3, cr: 0.1, fe: 0.03, kali: 150, i: 22)),
        .init(key: "yogurt", category: .dairy, pieceGrams: 100, calories: 59, protein: 10, fat: 0.4, carbs: 3.6, micro: .init(ca: 110, mg: 11, zn: 0.5, b6: 0.06, b9: 7, b12: 0.4, se: 5, kali: 141, i: 8)),
        .init(key: "cheese", category: .dairy, pieceGrams: 30, calories: 402, protein: 25, fat: 33, carbs: 1.3, micro: .init(d3: 0.6, ca: 721, mg: 28, zn: 3.1, a: 330, b6: 0.08, b9: 18, b12: 1.1, se: 15, cr: 0.5, fe: 0.7, kali: 98, i: 15)),
        .init(key: "oatmeal", category: .grains, pieceGrams: 100, calories: 389, protein: 17, fat: 7, carbs: 66, micro: .init(fiber: 11, ca: 54, mg: 177, zn: 4, e: 0.4, b6: 0.1, b9: 56, se: 28, cr: 4, fe: 4.7, kali: 429, i: 2)),
        .init(key: "rice", category: .grains, pieceGrams: 100, calories: 130, protein: 2.7, fat: 0.3, carbs: 28, micro: .init(fiber: 0.4, ca: 10, mg: 12, zn: 0.5, b6: 0.09, b9: 8, se: 8, fe: 0.2, kali: 35)),
        .init(key: "pasta", category: .grains, pieceGrams: 100, calories: 131, protein: 5, fat: 1.1, carbs: 25, micro: .init(fiber: 1.8, ca: 7, mg: 18, zn: 0.5, b6: 0.05, b9: 18, se: 36, fe: 0.9, kali: 44, i: 1)),
        .init(key: "bread", category: .grains, pieceGrams: 30, calories: 265, protein: 9, fat: 3.2, carbs: 49, micro: .init(fiber: 2.7, ca: 151, mg: 25, zn: 0.7, b6: 0.09, b9: 111, se: 22, cr: 1, fe: 3.6, kali: 115, i: 3)),
        .init(key: "potato", category: .vegetables, pieceGrams: 150, calories: 77, protein: 2, fat: 0.1, carbs: 17, micro: .init(fiber: 2.2, ca: 12, mg: 23, zn: 0.3, c: 19.7, b6: 0.3, b9: 15, se: 0.3, fe: 0.8, kali: 425, i: 3)),
        .init(key: "tomato", category: .vegetables, pieceGrams: 120, calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9, micro: .init(fiber: 1.2, ca: 10, mg: 11, zn: 0.2, k: 7.9, c: 13.7, a: 42, b6: 0.08, b9: 15, se: 0.4, kali: 237)),
        .init(key: "cucumber", category: .vegetables, pieceGrams: 100, calories: 15, protein: 0.7, fat: 0.1, carbs: 3.6, micro: .init(fiber: 0.5, ca: 16, mg: 13, zn: 0.2, k: 16.4, c: 2.8, a: 5, b6: 0.04, b9: 7, kali: 147)),
        .init(key: "carrot", category: .vegetables, pieceGrams: 60, calories: 41, protein: 0.9, fat: 0.2, carbs: 10, micro: .init(fiber: 2.8, ca: 33, mg: 12, zn: 0.2, k: 13.2, c: 5.9, a: 835, b6: 0.14, b9: 19, kali: 320)),
        .init(key: "onion", category: .vegetables, pieceGrams: 110, calories: 40, protein: 1.1, fat: 0.1, carbs: 9.3, micro: .init(fiber: 1.7, ca: 23, mg: 10, zn: 0.2, c: 7.4, b6: 0.12, b9: 19, se: 0.5, kali: 146, i: 1)),
        .init(key: "broccoli", category: .vegetables, pieceGrams: 100, calories: 34, protein: 2.8, fat: 0.4, carbs: 7, micro: .init(fiber: 2.6, ca: 47, mg: 21, zn: 0.4, k: 102, c: 89.2, a: 31, b6: 0.18, b9: 63, se: 2.5, cr: 11, fe: 0.7, kali: 316, i: 1)),
        .init(key: "spinach", category: .vegetables, pieceGrams: 100, calories: 23, protein: 2.9, fat: 0.4, carbs: 3.6, micro: .init(fiber: 2.2, ca: 99, mg: 79, zn: 0.5, k: 483, c: 28.1, a: 469, b6: 0.2, b9: 194, se: 1, fe: 2.7, kali: 558, i: 1)),
        .init(key: "banana", category: .fruits, pieceGrams: 120, calories: 89, protein: 1.1, fat: 0.3, carbs: 23, micro: .init(fiber: 2.6, ca: 5, mg: 27, zn: 0.2, c: 8.7, b6: 0.37, b9: 20, se: 1, kali: 358)),
        .init(key: "apple", category: .fruits, pieceGrams: 180, calories: 52, protein: 0.3, fat: 0.2, carbs: 14, micro: .init(fiber: 2.4, ca: 6, mg: 5, zn: 0.04, c: 4.6, a: 3, b6: 0.04, b9: 3, kali: 107)),
        .init(key: "olive_oil", category: .other, pieceGrams: 100, calories: 884, protein: 0, fat: 100, carbs: 0, micro: .init(k: 60.2, e: 14.4, fe: 0.6)),
        .init(key: "butter", category: .dairy, pieceGrams: 10, calories: 717, protein: 0.9, fat: 81, carbs: 0.1, micro: .init(d3: 1.5, ca: 24, mg: 2, zn: 0.1, a: 684, b6: 0.01, b9: 3, b12: 0.2, se: 1, kali: 24, i: 2)),
        .init(key: "sugar", category: .other, pieceGrams: 100, calories: 387, protein: 0, fat: 0, carbs: 100, micro: .init()),
        .init(key: "honey", category: .other, pieceGrams: 100, calories: 304, protein: 0.3, fat: 0, carbs: 82, micro: .init(fiber: 0.2, c: 0.5, b6: 0.02, b9: 2, fe: 0.4, kali: 52)),
        .init(key: "lentils", category: .grains, pieceGrams: 100, calories: 116, protein: 9, fat: 0.4, carbs: 20, micro: .init(fiber: 8, ca: 19, mg: 36, zn: 1.3, c: 1.5, b6: 0.18, b9: 181, se: 2.8, cr: 1, fe: 3.3, kali: 369, i: 2)),
        .init(key: "beans", category: .grains, pieceGrams: 100, calories: 127, protein: 8.7, fat: 0.5, carbs: 23, micro: .init(fiber: 6.4, ca: 28, mg: 45, zn: 1, c: 1.2, b6: 0.14, b9: 149, se: 1.2, cr: 2, fe: 2.1, kali: 405, i: 3)),
        .init(key: "almonds", category: .other, pieceGrams: 100, calories: 579, protein: 21, fat: 50, carbs: 22, micro: .init(fiber: 12, ca: 269, mg: 270, zn: 3.1, e: 25.6, b6: 0.14, b9: 44, se: 4.1, cr: 8, fe: 3.7, kali: 733)),
        .init(key: "garlic", category: .vegetables, pieceGrams: 3, calories: 149, protein: 6.4, fat: 0.5, carbs: 33, micro: .init(fiber: 2.1, ca: 181, mg: 25, zn: 1.2, c: 31.2, b6: 1.2, b9: 3, se: 14, cr: 1, fe: 1.7, kali: 401, i: 1)),
        .init(key: "lemon", category: .fruits, pieceGrams: 60, calories: 29, protein: 1.1, fat: 0.3, carbs: 9, micro: .init(fiber: 2.8, ca: 26, mg: 8, zn: 0.1, c: 53, b6: 0.08, b9: 11, fe: 0.6, kali: 138)),
        .init(key: "avocado", category: .fruits, pieceGrams: 150, calories: 160, protein: 2, fat: 15, carbs: 9, micro: .init(fiber: 7, ca: 12, mg: 29, zn: 0.6, k: 21, c: 10, e: 2.1, a: 7, b6: 0.26, b9: 81, kali: 485)),
        .init(key: "bell_pepper", category: .vegetables, pieceGrams: 120, calories: 31, protein: 1, fat: 0.3, carbs: 6, micro: .init(fiber: 2.1, ca: 7, mg: 12, zn: 0.3, k: 4.9, c: 127.7, a: 18, b6: 0.29, b9: 46, se: 0.1, kali: 211)),
        .init(key: "turkey", category: .meat, pieceGrams: 100, calories: 135, protein: 30, fat: 1, carbs: 0, micro: .init(d3: 0.2, ca: 14, mg: 30, zn: 2.5, b6: 0.5, b9: 7, b12: 1.2, se: 24, cr: 0.1, fe: 1.4, kali: 249, i: 6)),
    ]
  // swiftlint:enable line_length

    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<FoodProduct>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for seed in catalog {
            let m = seed.micro
            let product = FoodProduct(
                catalogKey: seed.key,
                category: seed.category,
                defaultPieceWeightGrams: seed.pieceGrams,
                caloriesPer100g: seed.calories,
                proteinPer100g: seed.protein,
                fatPer100g: seed.fat,
                carbsPer100g: seed.carbs,
                fiberPer100g: m.fiber,
                vitaminD3Per100g: m.d3,
                calciumPer100g: m.ca,
                magnesiumPer100g: m.mg,
                zincPer100g: m.zn,
                vitaminKPer100g: m.k,
                vitaminCPer100g: m.c,
                vitaminEPer100g: m.e,
                vitaminAPer100g: m.a,
                vitaminB6Per100g: m.b6,
                vitaminB9Per100g: m.b9,
                vitaminB12Per100g: m.b12,
                seleniumPer100g: m.se,
                chromiumPer100g: m.cr,
                ironPer100g: m.fe,
                potassiumPer100g: m.kali,
                iodinePer100g: m.i
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
