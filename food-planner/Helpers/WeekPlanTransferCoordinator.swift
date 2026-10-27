import Foundation
import Observation
import SwiftData

struct WeekPlanExportPresentation: Identifiable {
    let id = UUID()
    let document: FoodPlanDocument
    let suggestedFileName: String
    let averageNutrition: DailyNutrition?
    let filledDayCount: Int
    let mealCount: Int
}

struct WeekPlanSharePresentation: Identifiable {
    let id = UUID()
    let fileURL: URL
}

struct WeekPlanImportPresentation: Identifiable {
    let id = UUID()
    let document: FoodPlanDocument
    /// Week to apply into; `nil` means the current calendar week.
    var targetWeekStart: Date?
}

@MainActor
@Observable
final class WeekPlanTransferCoordinator {
    var exportPresentation: WeekPlanExportPresentation?
    var sharePresentation: WeekPlanSharePresentation?
    var importPresentation: WeekPlanImportPresentation?
    var errorMessage: String?
    var showsError = false

    private var modelContext: ModelContext?

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func beginExport(weekPlan: WeekPlan, targets: DailyNutrition?) {
        do {
            let document = try WeekPlanTransferService.makeDocument(from: weekPlan, targets: targets)
            exportPresentation = WeekPlanExportPresentation(
                document: document,
                suggestedFileName: WeekPlanTransferService.suggestedFileName(for: document),
                averageNutrition: WeekPlanTransferService.averageDailyNutrition(from: weekPlan),
                filledDayCount: document.filledDayCount,
                mealCount: document.mealCount
            )
        } catch {
            presentError(error)
        }
    }

    func confirmExport(fileName: String, document: FoodPlanDocument) {
        do {
            let url = try WeekPlanTransferService.writeTemporaryFile(document, fileName: fileName)
            exportPresentation = nil
            sharePresentation = WeekPlanSharePresentation(fileURL: url)
        } catch {
            presentError(error)
        }
    }

    func importFromFile(url: URL, targetWeekStart: Date? = nil) {
        do {
            let document = try WeekPlanTransferService.load(from: url)
            importPresentation = WeekPlanImportPresentation(
                document: document,
                targetWeekStart: targetWeekStart
            )
        } catch {
            presentError(error)
        }
    }

    func handleOpenURL(_ url: URL) -> Bool {
        guard WeekPlanTransferService.isFoodPlanURL(url) else { return false }
        importFromFile(url: url, targetWeekStart: nil)
        return true
    }

    func applyImport(
        document: FoodPlanDocument,
        to weekPlan: WeekPlan,
        mode: WeekPlanImportMode
    ) {
        guard let context = modelContext else { return }
        WeekPlanTransferService.apply(document, to: weekPlan, mode: mode, in: context)
        importPresentation = nil
    }

    func dismissExport() {
        exportPresentation = nil
    }

    func dismissShare() {
        if let url = sharePresentation?.fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        sharePresentation = nil
    }

    func dismissImport() {
        importPresentation = nil
    }

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showsError = true
    }
}
