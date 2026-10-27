import SwiftUI
import SwiftData

struct GenerateWeekPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WeekPlanGenerationCoordinator.self) private var coordinator
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("weekPlan.generate.intro")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let settings {
                        MealPlanTargetsCard(
                            target: settings.targetNutrition,
                            micronutrientFocus: settings.profileMicronutrientFocus,
                            titleKey: "weekPlan.generate.targets.title",
                            subtitleKey: "weekPlan.generate.targets.subtitle"
                        )
                    }

                    Button {
                        dismiss()
                        coordinator.startGeneration(replaceExisting: true)
                    } label: {
                        Text("weekPlan.generate.action")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppTheme.controlMinHeight)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(AppTheme.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appFormWidth()
            }
            .navigationTitle("weekPlan.generate.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .appFormSheetPresentation()
    }
}
