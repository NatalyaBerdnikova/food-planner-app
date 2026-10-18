import SwiftUI

struct ImportProgressView: View {
    @Bindable var coordinator: ImportCoordinator

    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.state {
                case .loading(let stage):
                    loadingContent(stage: stage)
                case .failed(let message):
                    errorContent(message: message)
                case .ready:
                    successContent
                case .idle:
                    SparklesLoader()
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
        .interactiveDismissDisabled({
            if case .loading = coordinator.state { return true }
            return false
        }())
        .presentationDetents([.medium, .large])
    }

    private func loadingContent(stage: ImportStage) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                SparklesLoader(
                    accessibilityLabel: LocalizedStringKey(stage.localizationKey)
                )

                VStack(spacing: 8) {
                    Text(LocalizedStringKey(stage.localizationKey))
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("import.progress.aiDisclosure")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("import.privacy.server")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(ImportStage.allCases.filter { $0 != .ready }) { item in
                        stageRow(item, current: stage)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    private func stageRow(_ stage: ImportStage, current: ImportStage) -> some View {
        let isDone = stage.rawValue < current.rawValue
        let isCurrent = stage == current
        return HStack(spacing: 12) {
            Image(systemName: isDone ? "checkmark.circle.fill" : (isCurrent ? "circle.inset.filled" : "circle"))
                .foregroundStyle(isDone || isCurrent ? AppTheme.accent : .secondary)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(stage.localizationKey))
                .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                .foregroundStyle(isCurrent || isDone ? .primary : .secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func errorContent(message: String) -> some View {
        ContentUnavailableView {
            Label("import.error.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("import.progress.retry") {
                coordinator.retryImport()
            }
            .buttonStyle(.borderedProminent)
            Button("common.cancel") {
                coordinator.dismissError()
            }
        }
    }

    private var successContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.success)
                .motionSafeSymbolEffect(.bounce)
                .accessibilityHidden(true)

            Text("import.progress.success")
                .font(.title2.bold())

            if let draft = coordinator.importedDraft {
                Text(draft.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("import.progress.matched \(draft.ingredients.count) \(draft.unresolvedIngredients.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("import.progress.review") {
                coordinator.openImportedRecipe()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
