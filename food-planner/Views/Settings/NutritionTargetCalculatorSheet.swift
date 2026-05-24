import SwiftUI

struct NutritionTargetCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onApply: (DailyNutrition) -> Void

    @State private var sex: BiologicalSex = .female
    @State private var ageText = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var targetWeightText = ""
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var proteinPerKg: Double = 1.6
    @State private var fatPerKg: Double = 1.0
    @State private var calculated: DailyNutrition?
    @State private var showInvalidInput = false

    var body: some View {
        NavigationStack {
            Form {
                parametersSection

                if let nutrition = calculated {
                    resultSection(nutrition)
                }
            }
            .navigationTitle("calculator.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("calculator.calculate") {
                        performCalculation()
                    }
                }
            }
            .alert("calculator.invalidInput", isPresented: $showInvalidInput) {
                Button("common.done") { }
            }
        }
    }

    private var parametersSection: some View {
        Group {
            Section("calculator.profile") {
                Picker("calculator.sex", selection: $sex) {
                    ForEach(BiologicalSex.allCases) { option in
                        Text(sexLabel(option)).tag(option)
                    }
                }

                TextField("calculator.age", text: $ageText)
                    .keyboardType(.numberPad)

                TextField("calculator.height", text: $heightText)
                    .keyboardType(.decimalPad)

                TextField("calculator.weight", text: $weightText)
                    .keyboardType(.decimalPad)

                TextField("calculator.targetWeight", text: $targetWeightText)
                    .keyboardType(.decimalPad)
            }

            Section("calculator.activity") {
                Picker("calculator.activityLevel", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(activityLabel(level)).tag(level)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("calculator.proteinPerKg")
                        Spacer()
                        Text(formatCoefficient(proteinPerKg))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $proteinPerKg, in: 1...3, step: 0.1)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("calculator.fatPerKg")
                        Spacer()
                        Text(formatCoefficient(fatPerKg))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $fatPerKg, in: 0.8...1.5, step: 0.1)
                }
            } footer: {
                Text("calculator.macrosPerKg.footer")
            }
        }
    }

    private func resultSection(_ nutrition: DailyNutrition) -> some View {
        Section {
            NutritionSummaryView(
                nutrition: nutrition,
                title: "calculator.result",
                embedded: true,
                macroLabelStyle: .full
            )

            Button {
                onApply(nutrition)
                dismiss()
            } label: {
                Text("calculator.use")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func formatCoefficient(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func sexLabel(_ sex: BiologicalSex) -> LocalizedStringResource {
        switch sex {
        case .female: "calculator.sex.female"
        case .male: "calculator.sex.male"
        }
    }

    private func activityLabel(_ level: ActivityLevel) -> LocalizedStringResource {
        switch level {
        case .sedentary: "calculator.activity.sedentary"
        case .light: "calculator.activity.light"
        case .moderate: "calculator.activity.moderate"
        case .active: "calculator.activity.active"
        case .veryActive: "calculator.activity.veryActive"
        }
    }

    private func performCalculation() {
        guard let input = buildInput() else {
            calculated = nil
            showInvalidInput = true
            return
        }
        calculated = NutritionTargetCalculator.calculate(input: input)
        if calculated == nil {
            showInvalidInput = true
        }
    }

    private func buildInput() -> NutritionTargetInput? {
        guard let age = Int(ageText.trimmingCharacters(in: .whitespaces)),
              let height = parseDouble(heightText),
              let weight = parseDouble(weightText),
              let targetWeight = parseDouble(targetWeightText) else {
            return nil
        }

        return NutritionTargetInput(
            sex: sex,
            age: age,
            heightCm: height,
            weightKg: weight,
            targetWeightKg: targetWeight,
            activityLevel: activityLevel,
            proteinGramsPerKg: proteinPerKg,
            fatGramsPerKg: fatPerKg
        )
    }

    private func parseDouble(_ text: String) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }
}
