import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionSession.self) private var subscriptionSession

    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue

    @Query private var recipes: [Recipe]
    @Query private var weekPlans: [WeekPlan]
    @Query private var foodProducts: [FoodProduct]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var fatText = ""
    @State private var carbsText = ""
    @State private var showNutritionCalculator = false
    @State private var selectedMicros: Set<MicronutrientKind> = []

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        Form {
            Section {
                LabeledContent("settings.subscription.status") {
                    Text(
                        subscriptionSession.hasFullAccess
                            ? "settings.subscription.active"
                            : "settings.subscription.inactive"
                    )
                    .foregroundStyle(subscriptionSession.hasFullAccess ? .green : .secondary)
                }

                if subscriptionSession.hasFullAccess {
                    Button {
                        restorePurchases()
                    } label: {
                        Label("settings.subscription.restore", systemImage: "goforward")
                    }
                }
            } header: {
                Text("settings.subscription.title")
            }

            if let settings {
                Section {
                    LabeledContent("onboarding.goal.title") {
                        Text(LocalizedStringKey(settings.profileGoal.localizationKey))
                    }
                    LabeledContent("onboarding.body.age") {
                        Text("\(settings.profileAge)")
                    }
                    LabeledContent("onboarding.body.weight") {
                        Text(String(format: "%.1f kg", settings.profileWeightKg))
                    }
                    LabeledContent("onboarding.body.targetWeight") {
                        Text(String(format: "%.1f kg", settings.profileTargetWeightKg))
                    }
                } header: {
                    Text("settings.profile.title")
                } footer: {
                    Text("settings.profile.footer")
                }

                Section {
                    ForEach(MicronutrientKind.allCases) { kind in
                        Toggle(isOn: Binding(
                            get: { selectedMicros.contains(kind) },
                            set: { isOn in
                                if isOn {
                                    if selectedMicros.count < 5 {
                                        selectedMicros.insert(kind)
                                    }
                                } else {
                                    selectedMicros.remove(kind)
                                }
                                persistMicronutrientFocus()
                            }
                        )) {
                            Text(LocalizedStringKey(kind.localizationKey))
                        }
                    }
                } header: {
                    Text("settings.micros.title")
                } footer: {
                    Text("settings.micros.footer")
                }
            }

            Section {
                Picker("settings.language", selection: $appLanguageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName)
                            .tag(language.rawValue)
                    }
                }
            } footer: {
                Text("settings.appearance.systemFooter")
            }

            Section {
                Button {
                    showNutritionCalculator = true
                } label: {
                    Label("settings.calculateTargets", systemImage: "function")
                }

                TextField("settings.target.calories", text: $caloriesText)
                    .keyboardType(.decimalPad)
                TextField("settings.target.protein", text: $proteinText)
                    .keyboardType(.decimalPad)
                TextField("settings.target.fat", text: $fatText)
                    .keyboardType(.decimalPad)
                TextField("settings.target.carbs", text: $carbsText)
                    .keyboardType(.decimalPad)
            } header: {
                Text("settings.target.title")
            } footer: {
                Text("settings.target.footer")
            }

            Section {
                LabeledContent("settings.storage.recipes") {
                    Text("\(recipes.count)")
                }
                LabeledContent("settings.storage.weekPlans") {
                    Text("\(weekPlans.count)")
                }
                LabeledContent("settings.productDB.count") {
                    Text("\(foodProducts.count)")
                }
                if let active = settings?.activeWeekPlan {
                    LabeledContent("settings.storage.activePlan") {
                        Text(active.weekStartDate, format: .dateTime.day().month().year())
                    }
                }
            } header: {
                Text("settings.storage.title")
            } footer: {
                Text("settings.storage.footer")
            }
        }
        .navigationTitle("nav.settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSettings)
        .onDisappear(perform: saveTargets)
        .sheet(isPresented: $showNutritionCalculator) {
            NutritionTargetCalculatorSheet { nutrition in
                applyCalculatedTargets(nutrition)
            }
        }
    }

    private func applyCalculatedTargets(_ nutrition: DailyNutrition) {
        caloriesText = format(nutrition.calories)
        proteinText = format(nutrition.protein)
        fatText = format(nutrition.fat)
        carbsText = format(nutrition.carbs)
        saveTargets()
    }

    private func loadSettings() {
        let appSettings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.load(from: appSettings)
        caloriesText = format(appSettings.targetCalories)
        proteinText = format(appSettings.targetProtein)
        fatText = format(appSettings.targetFat)
        carbsText = format(appSettings.targetCarbs)
        selectedMicros = Set(appSettings.profileMicronutrientFocus)
    }

    private func persistMicronutrientFocus() {
        let settings = AppSettingsService.settings(in: modelContext)
        settings.profileMicronutrientFocus = Array(selectedMicros)
        LocalPersistence.save(modelContext)
    }

    private func saveTargets() {
        let settings = AppSettingsService.settings(in: modelContext)
        settings.targetCalories = Double(caloriesText.replacingOccurrences(of: ",", with: ".")) ?? settings.targetCalories
        settings.targetProtein = Double(proteinText.replacingOccurrences(of: ",", with: ".")) ?? settings.targetProtein
        settings.targetFat = Double(fatText.replacingOccurrences(of: ",", with: ".")) ?? settings.targetFat
        settings.targetCarbs = Double(carbsText.replacingOccurrences(of: ",", with: ".")) ?? settings.targetCarbs
        LocalPersistence.save(modelContext)
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private func restorePurchases() {
        subscriptionSession.showLoader()

        PurchaseService.restorePurchases { purchased in
            Task { @MainActor in
                subscriptionSession.hideLoader()

                if purchased {
                    let settings = AppSettingsService.settings(in: modelContext)
                    subscriptionSession.upgradeToPro(settings: settings, in: modelContext)
                } else {
                    subscriptionSession.showAlert(String(localized: "subscription.restoreEmpty"))
                }
            }
        } errorCallback: { message in
            Task { @MainActor in
                subscriptionSession.hideLoader()
                subscriptionSession.showAlert(message)
            }
        }
    }
}
