import SwiftUI

struct ExportWeekPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WeekPlanTransferCoordinator.self) private var transfer

    let presentation: WeekPlanExportPresentation

    @State private var fileName: String
    @FocusState private var isNameFocused: Bool

    init(presentation: WeekPlanExportPresentation) {
        self.presentation = presentation
        _fileName = State(initialValue: presentation.suggestedFileName)
    }

    private var trimmedName: String {
        fileName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard

                    if let average = presentation.averageNutrition {
                        MealPlanTargetsCard(
                            target: average,
                            titleKey: "weekPlan.export.average.title",
                            subtitleKey: "weekPlan.export.average.subtitle"
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("weekPlan.export.filename.title")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        HStack(spacing: 8) {
                            TextField("weekPlan.export.filename.placeholder", text: $fileName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($isNameFocused)

                            Text(".\(FoodPlanUTType.fileExtension)")
                                .font(.subheadline.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            AppTheme.nestedFill,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )

                        Text("weekPlan.export.filename.hint")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        transfer.confirmExport(fileName: trimmedName, document: presentation.document)
                        dismiss()
                    } label: {
                        Text("weekPlan.export.action")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppTheme.controlMinHeight)
                            .background(
                                AppTheme.accent,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(trimmedName.isEmpty)
                    .padding(.top, 4)
                }
                .padding(AppTheme.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appFormWidth()
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("weekPlan.export.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        transfer.dismissExport()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .appFormSheetPresentation()
        .onAppear {
            isNameFocused = true
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("weekPlan.import.summary \(presentation.filledDayCount) \(presentation.mealCount)")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("weekPlan.export.summary.hint")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.nestedFill,
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
    }
}
