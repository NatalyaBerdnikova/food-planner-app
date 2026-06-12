import Foundation
import Observation
import SwiftData

enum ImportState: Equatable {
    case idle
    case loading
    case ready(ImportedRecipeDraft)
    case failed(String)

    static func == (lhs: ImportState, rhs: ImportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.ready(let a), .ready(let b)):
            return a.name == b.name && a.sourceURL == b.sourceURL
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

@MainActor
@Observable
final class ImportCoordinator {
    var state: ImportState = .idle
    var showProgress = false
    var editingDraft: ImportedRecipeDraft?
    var importedDraft: ImportedRecipeDraft?

    private var importTask: Task<Void, Never>?

    func handleOpenURL(_ url: URL) {
        guard url.scheme == ImportAppGroup.importURLScheme else { return }
        if let pending = ImportAppGroup.consumePendingImportURL() {
            startImport(urlString: pending)
        } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryURL = components.queryItems?.first(where: { $0.name == "url" })?.value {
            startImport(urlString: queryURL)
        }
    }

    func checkPendingImport() {
        guard case .idle = state,
              let pending = ImportAppGroup.consumePendingImportURL() else {
            return
        }
        startImport(urlString: pending)
    }

    func startImport(urlString: String) {
        importTask?.cancel()
        state = .loading
        showProgress = true
        importedDraft = nil

        importTask = Task {
            await performImport(urlString: urlString)
        }
    }

    func cancelImport() {
        importTask?.cancel()
        importTask = nil
        state = .idle
        showProgress = false
    }

    func dismissError() {
        state = .idle
        showProgress = false
    }

    func openImportedRecipe() {
        showProgress = false
        editingDraft = importedDraft
    }

    private func performImport(urlString: String) async {
        guard let context = ModelContextProvider.shared else {
            state = .failed(RecipeImportError.networkFailure.localizedDescription)
            return
        }

        do {
            let draft = try await InstagramImportService.importRecipe(from: urlString, in: context)
            guard !Task.isCancelled else { return }
            importedDraft = draft
            state = .ready(draft)
        } catch let error as RecipeImportError {
            guard !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(RecipeImportError.networkFailure.localizedDescription)
        }
    }
}

@MainActor
enum ModelContextProvider {
    static weak var shared: ModelContext?
}
