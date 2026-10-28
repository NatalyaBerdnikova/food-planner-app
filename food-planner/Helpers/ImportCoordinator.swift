import Foundation
import Observation
import SwiftData

enum ImportStage: Int, CaseIterable, Identifiable {
    case fetchingPost
    case readingContent
    case parsingRecipe
    case matchingIngredients
    case ready

    var id: Int { rawValue }

    var localizationKey: String {
        switch self {
        case .fetchingPost: "import.stage.fetching"
        case .readingContent: "import.stage.reading"
        case .parsingRecipe: "import.stage.parsing"
        case .matchingIngredients: "import.stage.matching"
        case .ready: "import.stage.ready"
        }
    }
}

enum ImportState: Equatable {
    case idle
    case loading(ImportStage)
    case ready(ImportedRecipeDraft)
    case failed(String)

    static func == (lhs: ImportState, rhs: ImportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading(let a), .loading(let b)):
            return a == b
        case (.ready(let a), .ready(let b)):
            return a.id == b.id
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct ImportProgressPresentation: Identifiable {
    let id = UUID()
}

@MainActor
@Observable
final class ImportCoordinator {
    var state: ImportState = .idle
    var progressPresentation: ImportProgressPresentation?
    var editingDraft: ImportedRecipeDraft?
    var importedDraft: ImportedRecipeDraft?
    var lastAttemptedURL: String?

    private var importTask: Task<Void, Never>?
    private var modelContext: ModelContext?

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handleOpenURL(_ url: URL) {
        guard url.scheme == ImportAppGroup.importURLScheme else { return }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryURL = components.queryItems?.first(where: { $0.name == "url" })?.value,
           !queryURL.isEmpty {
            _ = ImportAppGroup.consumePendingImportURL()
            startImport(urlString: queryURL)
            return
        }

        checkPendingImport()
    }

    func checkPendingImport() {
        guard case .idle = state else { return }
        guard let pending = ImportAppGroup.consumePendingImportURL(), !pending.isEmpty else {
            return
        }
        startImport(urlString: pending)
    }

    func startImport(urlString: String) {
        guard modelContext != nil else {
            ImportAppGroup.savePendingImportURL(urlString)
            return
        }

        importTask?.cancel()
        lastAttemptedURL = urlString
        state = .loading(.fetchingPost)
        progressPresentation = ImportProgressPresentation()
        importedDraft = nil
        editingDraft = nil
        AppAnalytics.logInstagramImportStart(source: "instagram")

        importTask = Task {
            await performImport(urlString: urlString)
        }
    }

    func retryImport() {
        guard let lastAttemptedURL else { return }
        startImport(urlString: lastAttemptedURL)
    }

    func cancelImport() {
        importTask?.cancel()
        importTask = nil
        state = .idle
        progressPresentation = nil
    }

    func dismissError() {
        state = .idle
        progressPresentation = nil
    }

    func openImportedRecipe() {
        progressPresentation = nil
        editingDraft = importedDraft
    }

    func clearDraft() {
        importedDraft = nil
        editingDraft = nil
        state = .idle
    }

    private func performImport(urlString: String) async {
        guard let context = modelContext else {
            state = .failed(RecipeImportError.networkFailure.localizedDescription)
            return
        }

        do {
            let draft = try await InstagramImportService.importRecipe(
                from: urlString,
                in: context,
                onStage: { [weak self] stage in
                    self?.state = .loading(stage)
                }
            )
            guard !Task.isCancelled else { return }
            importedDraft = draft
            state = .ready(draft)
            AppAnalytics.logInstagramImportSuccess(itemsCount: draft.ingredients.count)
        } catch let error as RecipeImportError {
            guard !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
            AppAnalytics.logInstagramImportError(errorCode: error.analyticsCode)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(RecipeImportError.networkFailure.localizedDescription)
            AppAnalytics.logInstagramImportError(errorCode: "network_failure")
        }
    }
}
