import Foundation
import SwiftData
import UniformTypeIdentifiers
import UIKit

enum WeekPlanTransferError: LocalizedError {
    case emptyWeek
    case invalidFile
    case unsupportedVersion(Int)
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .emptyWeek:
            String(localized: "weekPlan.transfer.error.empty")
        case .invalidFile:
            String(localized: "weekPlan.transfer.error.invalid")
        case .unsupportedVersion:
            String(localized: "weekPlan.transfer.error.version")
        case .writeFailed:
            String(localized: "weekPlan.transfer.error.write")
        }
    }
}

@MainActor
enum WeekPlanTransferService {
    private static let maxImagePixel: CGFloat = 512
    private static let maxImageBytes = 180_000
    private static let jpegQuality: CGFloat = 0.72

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func makeDocument(
        from weekPlan: WeekPlan,
        targets: DailyNutrition?
    ) throws -> FoodPlanDocument {
        let calendar = Calendar.current
        let weekStart = calendar.startOfWeek(for: weekPlan.weekStartDate)
        let sortedDays = weekPlan.dayPlans.sorted { $0.date < $1.date }

        var days: [FoodPlanDayDTO] = []
        for dayPlan in sortedDays {
            let offset = calendar.dateComponents([.day], from: weekStart, to: calendar.startOfDay(for: dayPlan.date)).day ?? 0
            guard (0..<7).contains(offset) else { continue }
            let meals = dayPlan.meals.compactMap(makeMealDTO(from:))
            days.append(FoodPlanDayDTO(dayOffset: offset, meals: meals))
        }

        guard days.contains(where: { !$0.meals.isEmpty }) else {
            throw WeekPlanTransferError.emptyWeek
        }

        let targetsDTO = targets.map {
            FoodPlanTargetsDTO(
                calories: $0.calories,
                protein: $0.protein,
                fat: $0.fat,
                carbs: $0.carbs
            )
        }

        return FoodPlanDocument(
            formatVersion: FoodPlanDocument.currentFormatVersion,
            createdAt: .now,
            appVersion: AppVars.appVersion,
            targets: targetsDTO,
            days: days.sorted { $0.dayOffset < $1.dayOffset }
        )
    }

    static func suggestedFileName(for document: FoodPlanDocument) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "FoodPlan-\(formatter.string(from: document.createdAt))"
    }

    static func sanitizedFileName(_ raw: String) -> String {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = ".\(FoodPlanUTType.fileExtension)"
        if name.lowercased().hasSuffix(suffix) {
            name = String(name.dropLast(suffix.count))
        }
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        name = name
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return "FoodPlan-\(formatter.string(from: .now))"
        }
        return name
    }

    static func writeTemporaryFile(
        _ document: FoodPlanDocument,
        fileName: String? = nil
    ) throws -> URL {
        let data: Data
        do {
            data = try encoder.encode(document)
        } catch {
            throw WeekPlanTransferError.writeFailed
        }

        let baseName = sanitizedFileName(fileName ?? suggestedFileName(for: document))
        let fullName = "\(baseName).\(FoodPlanUTType.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fullName)

        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw WeekPlanTransferError.writeFailed
        }
    }

    static func averageDailyNutrition(from weekPlan: WeekPlan) -> DailyNutrition? {
        let filledDays = weekPlan.dayPlans.filter { !$0.meals.isEmpty }
        guard !filledDays.isEmpty else { return nil }

        var totals = DailyNutrition.zero
        for dayPlan in filledDays {
            let day = NutritionCalculator.from(dayPlan: dayPlan)
            totals.calories += day.calories
            totals.protein += day.protein
            totals.fat += day.fat
            totals.carbs += day.carbs
        }

        let dayCount = Double(filledDays.count)
        return DailyNutrition(
            calories: totals.calories / dayCount,
            protein: totals.protein / dayCount,
            fat: totals.fat / dayCount,
            carbs: totals.carbs / dayCount
        )
    }

    static func load(from url: URL) throws -> FoodPlanDocument {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw WeekPlanTransferError.invalidFile
        }

        let document: FoodPlanDocument
        do {
            document = try decoder.decode(FoodPlanDocument.self, from: data)
        } catch {
            throw WeekPlanTransferError.invalidFile
        }

        guard document.formatVersion <= FoodPlanDocument.currentFormatVersion else {
            throw WeekPlanTransferError.unsupportedVersion(document.formatVersion)
        }
        guard !document.days.isEmpty else {
            throw WeekPlanTransferError.invalidFile
        }
        return document
    }

    static func isFoodPlanURL(_ url: URL) -> Bool {
        if url.pathExtension.lowercased() == FoodPlanUTType.fileExtension {
            return true
        }
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type.conforms(to: FoodPlanUTType.utType)
        }
        return false
    }

    /// Average daily macros across filled days in the shared plan.
    static func averageDailyNutrition(
        from document: FoodPlanDocument,
        in context: ModelContext
    ) -> DailyNutrition? {
        let filledDays = document.days.filter { !$0.meals.isEmpty }
        guard !filledDays.isEmpty else { return nil }

        var totals = DailyNutrition.zero
        for day in filledDays {
            for meal in day.meals {
                let mealNutrition = recipeNutrition(meal.recipe, in: context)
                totals.calories += mealNutrition.calories
                totals.protein += mealNutrition.protein
                totals.fat += mealNutrition.fat
                totals.carbs += mealNutrition.carbs
            }
        }

        guard totals.calories > 0 else { return nil }
        let dayCount = Double(filledDays.count)
        return DailyNutrition(
            calories: totals.calories / dayCount,
            protein: totals.protein / dayCount,
            fat: totals.fat / dayCount,
            carbs: totals.carbs / dayCount
        )
    }

    private static func recipeNutrition(
        _ recipe: FoodPlanRecipeDTO,
        in context: ModelContext
    ) -> DailyNutrition {
        var totals = NutrientTotals.zero
        for item in recipe.ingredients {
            guard let catalogKey = item.foodProductCatalogKey,
                  let product = FoodCatalogSeeder.product(forKey: catalogKey, in: context)
            else { continue }
            let unit = MeasurementUnit(rawValue: item.unit) ?? .gram
            let grams = UnitConverter.grams(
                quantity: item.quantity,
                unit: unit,
                product: product
            )
            guard grams > 0 else { continue }
            totals = totals + product.nutrientsPer100g.scaled(by: grams / 100.0)
        }
        return totals.macros
    }

    static func apply(
        _ document: FoodPlanDocument,
        to weekPlan: WeekPlan,
        mode: WeekPlanImportMode,
        in context: ModelContext
    ) {
        let calendar = Calendar.current
        let weekStart = calendar.startOfWeek(for: weekPlan.weekStartDate)
        let daysByOffset = Dictionary(
            document.days.map { ($0.dayOffset, $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let dayPlan = WeekPlanService.dayPlan(for: date, in: weekPlan, context: context)
            guard let dto = daysByOffset[offset], !dto.meals.isEmpty else { continue }

            switch mode {
            case .replaceWeek:
                MealPlanGenerator.removeMeals(from: dayPlan, in: context)
                insert(meals: dto.meals, into: dayPlan, in: context)
            case .fillEmptyDaysOnly:
                guard dayPlan.meals.isEmpty else { continue }
                insert(meals: dto.meals, into: dayPlan, in: context)
            }
        }

        WeekPlanService.syncShoppingItems(for: weekPlan, in: context)
        LocalPersistence.save(context)
    }

    private static func insert(
        meals: [FoodPlanMealDTO],
        into dayPlan: DayPlan,
        in context: ModelContext
    ) {
        var existing = dayPlan.meals
        for mealDTO in meals {
            guard let mealType = MealType(rawValue: mealDTO.mealType) else { continue }
            let recipe = makeRecipe(from: mealDTO.recipe, in: context)
            let meal = Meal(
                mealType: mealType,
                date: dayPlan.date,
                recipe: recipe,
                dayPlan: dayPlan
            )
            context.insert(meal)
            existing.append(meal)
        }
        dayPlan.meals = existing
    }

    private static func makeMealDTO(from meal: Meal) -> FoodPlanMealDTO? {
        guard let recipe = meal.recipe else { return nil }
        return FoodPlanMealDTO(
            mealType: meal.mealType.rawValue,
            recipe: makeRecipeDTO(from: recipe)
        )
    }

    private static func makeRecipeDTO(from recipe: Recipe) -> FoodPlanRecipeDTO {
        FoodPlanRecipeDTO(
            catalogRecipeId: recipe.catalogRecipeId,
            name: recipe.name,
            servings: recipe.servings,
            steps: recipe.steps,
            cookTimeMinutes: recipe.cookTimeMinutes,
            mealTypeTags: recipe.mealTypeTags.map(\.rawValue).sorted(),
            caloriesPer100g: recipe.caloriesPer100g,
            proteinPer100g: recipe.proteinPer100g,
            fatPer100g: recipe.fatPer100g,
            carbsPer100g: recipe.carbsPer100g,
            imageJPEGBase64: compressedImageBase64(from: recipe.imageData),
            ingredients: recipe.ingredients.map(makeIngredientDTO(from:))
        )
    }

    private static func makeIngredientDTO(from ingredient: Ingredient) -> FoodPlanIngredientDTO {
        FoodPlanIngredientDTO(
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit.rawValue,
            category: ingredient.category.rawValue,
            foodProductCatalogKey: ingredient.foodProduct?.catalogKey
        )
    }

    private static func makeRecipe(from dto: FoodPlanRecipeDTO, in context: ModelContext) -> Recipe {
        let tags = Set(dto.mealTypeTags.compactMap(MealType.init(rawValue:)))
        let recipe = Recipe(
            name: dto.name,
            catalogRecipeId: dto.catalogRecipeId,
            servings: max(dto.servings, 1),
            imageData: imageData(fromBase64: dto.imageJPEGBase64),
            steps: dto.steps,
            cookTimeMinutes: max(dto.cookTimeMinutes, 0),
            mealTypeTags: tags,
            caloriesPer100g: dto.caloriesPer100g,
            proteinPer100g: dto.proteinPer100g,
            fatPer100g: dto.fatPer100g,
            carbsPer100g: dto.carbsPer100g
        )
        context.insert(recipe)

        let ingredients = dto.ingredients.map { item in
            let unit = MeasurementUnit(rawValue: item.unit) ?? .gram
            let category = IngredientCategory(rawValue: item.category) ?? .other
            let product = item.foodProductCatalogKey.flatMap {
                FoodCatalogSeeder.product(forKey: $0, in: context)
            }
            return Ingredient(
                name: item.name,
                quantity: item.quantity,
                unit: unit,
                category: category,
                recipe: recipe,
                foodProduct: product
            )
        }
        for ingredient in ingredients {
            context.insert(ingredient)
        }
        recipe.ingredients = ingredients
        recipe.recalculateNutrition()
        return recipe
    }

    private static func compressedImageBase64(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        guard let image = UIImage(data: data) else {
            return data.count <= maxImageBytes ? data.base64EncodedString() : nil
        }

        let maxSide = max(image.size.width, image.size.height)
        let scale = maxSide > maxImagePixel ? maxImagePixel / maxSide : 1
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard var jpeg = rendered.jpegData(compressionQuality: jpegQuality) else { return nil }
        if jpeg.count > maxImageBytes {
            jpeg = rendered.jpegData(compressionQuality: 0.45) ?? jpeg
        }
        guard jpeg.count <= maxImageBytes * 2 else { return nil }
        return jpeg.base64EncodedString()
    }

    private static func imageData(fromBase64 string: String?) -> Data? {
        guard let string, !string.isEmpty else { return nil }
        return Data(base64Encoded: string)
    }
}
