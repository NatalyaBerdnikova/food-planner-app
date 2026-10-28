import SwiftUI
import SwiftData

struct ImportWeekPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(WeekPlanTransferCoordinator.self) private var transfer
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    let document: FoodPlanDocument
    let initialWeekStart: Date

    @State private var selectedWeekStart: Date
    @State private var mode: WeekPlanImportMode = .replaceWeek

    init(document: FoodPlanDocument, initialWeekStart: Date) {
        self.document = document
        self.initialWeekStart = initialWeekStart
        _selectedWeekStart = State(
            initialValue: Calendar.current.startOfWeek(for: initialWeekStart)
        )
    }

    private var averageNutrition: DailyNutrition? {
        WeekPlanTransferService.averageDailyNutrition(from: document, in: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard

                    VStack(alignment: .leading, spacing: 10) {
                        Text("weekPlan.import.week.title")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        WeekRangeSwitcher(weekStart: $selectedWeekStart)
                    }

                    if let averageNutrition {
                        MealPlanTargetsCard(
                            target: averageNutrition,
                            titleKey: "weekPlan.import.average.title",
                            subtitleKey: "weekPlan.import.average.subtitle"
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("weekPlan.import.mode.title")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        ForEach(WeekPlanImportMode.allCases) { option in
                            modeRow(option)
                        }
                    }

                    Button(action: applyImport) {
                        Text("weekPlan.import.action")
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
                    .padding(.top, 4)
                }
                .padding(AppTheme.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appFormWidth()
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("weekPlan.import.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        transfer.dismissImport()
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
            transfer.attach(modelContext: modelContext)
            let analyticsMode = mode == .replaceWeek ? "replace" : "fill_empty"
            AppAnalytics.logPlanImportPreview(mode: analyticsMode)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("weekPlan.import.summary \(document.filledDayCount) \(document.mealCount)")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("weekPlan.import.summary.hint")
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

    private func modeRow(_ option: WeekPlanImportMode) -> some View {
        let isSelected = mode == option
        return Button {
            mode = option
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.accent : .secondary)
                    .font(.title3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.titleKey)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(option.subtitleKey)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.elevated,
                in: RoundedRectangle(cornerRadius: AppTheme.nestedCardRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.nestedCardRadius, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.accent.opacity(0.45) : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func applyImport() {
        let weekPlan = WeekPlanService.weekPlan(
            forWeekStarting: selectedWeekStart,
            from: weekPlans,
            in: modelContext
        )
        let currentWeek = Calendar.current.startOfWeek(for: .now)
        let offset = Calendar.current.dateComponents(
            [.weekOfYear],
            from: currentWeek,
            to: Calendar.current.startOfWeek(for: selectedWeekStart)
        ).weekOfYear ?? 0
        transfer.applyImport(
            document: document,
            to: weekPlan,
            mode: mode,
            targetWeekOffset: offset
        )
        dismiss()
    }
}
