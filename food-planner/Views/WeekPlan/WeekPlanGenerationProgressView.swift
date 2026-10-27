import SwiftUI

struct WeekPlanGenerationProgressView: View {
    @Bindable var coordinator: WeekPlanGenerationCoordinator

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
            .navigationTitle("weekPlan.generate.progress.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsToolbarCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.cancel", role: .cancel) {
                            cancelFromToolbar()
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
        .appFormSheetPresentation()
    }

    private var showsToolbarCancel: Bool {
        switch coordinator.state {
        case .loading, .failed:
            true
        default:
            false
        }
    }

    private func cancelFromToolbar() {
        switch coordinator.state {
        case .loading:
            coordinator.cancelGeneration()
        case .failed:
            coordinator.dismissError()
        default:
            break
        }
    }

    private func loadingContent(stage: WeekPlanGenerationStage) -> some View {
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

                    Text("weekPlan.generate.progress.disclosure")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(WeekPlanGenerationStage.allCases.filter { $0 != .ready }) { item in
                        stageRow(item, current: stage)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
            .padding(24)
            .appFormWidth()
        }
    }

    private func stageRow(_ stage: WeekPlanGenerationStage, current: WeekPlanGenerationStage) -> some View {
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
            Label {
                Text("weekPlan.generate.error.title")
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .symbolRenderingMode(.hierarchical)
            }
        } description: {
            Text(message)
                .multilineTextAlignment(.center)
        } actions: {
            Button {
                coordinator.startGeneration(replaceExisting: true)
            } label: {
                Text("weekPlan.generate.retry")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppTheme.accent)
        }
        .padding(.horizontal, 24)
        .appFormWidth()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var successContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.success)
                .motionSafeSymbolEffect(.bounce)
                .accessibilityHidden(true)

            Text("weekPlan.generate.success.title")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("weekPlan.generate.success.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("weekPlan.generate.success.done") {
                coordinator.dismissSuccess()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
        }
        .padding(24)
        .appFormWidth()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
