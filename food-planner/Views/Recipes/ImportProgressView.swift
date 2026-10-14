import SwiftUI

struct ImportProgressView: View {
    @Bindable var coordinator: ImportCoordinator

    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.state {
                case .loading:
                    loadingContent
                case .failed(let message):
                    errorContent(message: message)
                case .ready:
                    successContent
                case .idle:
                    ProgressView()
                }
            }
            .navigationTitle("import.progress.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .loading = coordinator.state {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.cancel") {
                            coordinator.cancelImport()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(coordinator.state == .loading)
    }

    private var loadingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text("import.progress.loading")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func errorContent(message: String) -> some View {
        ContentUnavailableView {
            Label("import.error.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("common.cancel") {
                coordinator.dismissError()
            }
        }
    }

    private var successContent: some View {
        ContentUnavailableView {
            Label("import.progress.success", systemImage: "checkmark.circle")
        } description: {
            if let draft = coordinator.importedDraft {
                Text(draft.name)
            }
        } actions: {
            Button("import.progress.review") {
                coordinator.openImportedRecipe()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
