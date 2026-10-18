import SwiftUI
import SwiftData

struct NutritionTargetCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let settings: AppSettings
    let onApply: (DailyNutrition) -> Void

    @State private var sex: BiologicalSex
    @State private var age: Int
    @State private var heightCm: Double
    @State private var weightKg: Double
    @State private var targetWeightKg: Double
    @State private var activityLevel: ActivityLevel
    @State private var proteinPerKg: Double
    @State private var fatPerKg: Double

    init(settings: AppSettings, onApply: @escaping (DailyNutrition) -> Void) {
        self.settings = settings
        self.onApply = onApply
        _sex = State(initialValue: settings.profileSex)
        _age = State(initialValue: min(max(settings.profileAge, 14), 80))
        _heightCm = State(initialValue: min(max(settings.profileHeightCm, 140), 210))
        _weightKg = State(initialValue: min(max(settings.profileWeightKg, 40), 180))
        _targetWeightKg = State(initialValue: min(max(settings.profileTargetWeightKg, 40), 180))
        _activityLevel = State(initialValue: settings.profileActivity)
        _proteinPerKg = State(initialValue: settings.profileGoal.proteinGramsPerKg)
        _fatPerKg = State(initialValue: settings.profileGoal.fatGramsPerKg)
    }

    private var liveNutrition: DailyNutrition? {
        NutritionTargetCalculator.calculate(input: currentInput)
    }

    private var currentInput: NutritionTargetInput {
        NutritionTargetInput(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            targetWeightKg: targetWeightKg,
            activityLevel: activityLevel,
            proteinGramsPerKg: proteinPerKg,
            fatGramsPerKg: fatPerKg
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                liveTargetsHeader

                ScrollView {
                    VStack(spacing: 12) {
                        inputsCard
                    }
                    .padding(AppTheme.contentPadding)
                }
            }
            .background(AppTheme.canvas)
            .navigationTitle("calculator.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        save()
                    }
                    .disabled(liveNutrition == nil)
                }
            }
        }
    }

    private var liveTargetsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("calculator.result")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let nutrition = liveNutrition {
                NutritionSummaryView(
                    nutrition: nutrition,
                    embedded: true,
                    macroLabelStyle: .full
                )
            }
        }
        .padding(AppTheme.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevated)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var inputsCard: some View {
        VStack(spacing: 14) {
            Picker("onboarding.body.sex", selection: $sex) {
                Text("calculator.sex.female").tag(BiologicalSex.female)
                Text("calculator.sex.male").tag(BiologicalSex.male)
            }
            .pickerStyle(.segmented)

            ageRow

            sliderRow(
                title: "onboarding.body.height",
                valueText: "\(Int(heightCm)) cm",
                value: $heightCm,
                range: 140...210,
                step: 1
            )
            sliderRow(
                title: "onboarding.body.weight",
                valueText: String(format: "%.1f kg", weightKg),
                value: $weightKg,
                range: 40...180,
                step: 0.5
            )
            sliderRow(
                title: "onboarding.body.targetWeight",
                valueText: String(format: "%.1f kg", targetWeightKg),
                value: $targetWeightKg,
                range: 40...180,
                step: 0.5
            )

            Picker("calculator.activityLevel", selection: $activityLevel) {
                ForEach(ActivityLevel.allCases) { level in
                    Text(LocalizedStringKey(level.localizationKey)).tag(level)
                }
            }

            sliderRow(
                title: "calculator.proteinPerKg",
                valueText: formatCoefficient(proteinPerKg),
                value: $proteinPerKg,
                range: NutritionTargetCalculator.proteinGramsPerKgRange,
                step: 0.1
            )
            sliderRow(
                title: "calculator.fatPerKg",
                valueText: formatCoefficient(fatPerKg),
                value: $fatPerKg,
                range: NutritionTargetCalculator.fatGramsPerKgRange,
                step: 0.1
            )
        }
        .padding(14)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    private var ageRow: some View {
        HStack {
            Text("onboarding.body.age")
                .font(.subheadline.weight(.medium))
            Spacer()
            Text("\(age)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Stepper("", value: $age, in: 14...80)
                .labelsHidden()
        }
    }

    private func sliderRow(
        title: LocalizedStringKey,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(valueText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
                .tint(AppTheme.accent)
        }
    }

    private func formatCoefficient(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func save() {
        guard let nutrition = liveNutrition else { return }
        settings.apply(calculatorInput: currentInput, nutrition: nutrition)
        LocalPersistence.save(modelContext)
        onApply(nutrition)
        dismiss()
    }
}
