import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionSession: SubscriptionSession

    @AppStorage("openAIAPIKey") private var apiKey = ""
    @AppStorage("productDatabaseName") private var productDatabaseName = ""
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage(AppColorScheme.storageKey) private var appColorSchemeRaw = AppColorScheme.system.rawValue

    @Query private var foodProducts: [FoodProduct]
    @Query private var recipes: [Recipe]
    @Query private var weekPlans: [WeekPlan]

    @State private var settings: AppSettings?
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var fatText = ""
    @State private var carbsText = ""
    @State private var showNutritionCalculator = false

    var body: some View {
        Form {
            Section {
                if subscriptionSession.isPro {
                    LabeledContent("settings.subscription.status") {
                        Text("settings.subscription.active")
                            .foregroundStyle(.green)
                    }
                } else {
                    Button {
                        subscriptionSession.showPayment()
                    } label: {
                        Label("settings.subscription.buy", systemImage: "sparkles")
                    }

                    Button {
                        restorePurchases()
                    } label: {
                        Label("settings.subscription.restore", systemImage: "goforward")
                    }
                }
            } header: {
                Text("settings.subscription.title")
            }

            Section {
                Picker("settings.language", selection: $appLanguageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName)
                            .tag(language.rawValue)
                    }
                }

                Picker("settings.theme", selection: $appColorSchemeRaw) {
                    ForEach(AppColorScheme.allCases) { theme in
                        Text(theme.displayName)
                            .tag(theme.rawValue)
                    }
                }
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

            Section {
                SecureField("settings.apiKey", text: $apiKey)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("settings.api")
            } footer: {
                Text("settings.api.footer")
            }

            Section {
                TextField("settings.productDBName", text: $productDatabaseName)
                LabeledContent("settings.productDB.count") {
                    Text("\(foodProducts.count)")
                }
            } header: {
                Text("settings.productDB")
            } footer: {
                Text("settings.productDB.footer")
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
        settings = appSettings
        subscriptionSession.load(from: appSettings)
        caloriesText = format(appSettings.targetCalories)
        proteinText = format(appSettings.targetProtein)
        fatText = format(appSettings.targetFat)
        carbsText = format(appSettings.targetCarbs)
    }

    private func saveTargets() {
        guard let settings else { return }
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
                    guard let settings else { return }
                    subscriptionSession.upgradeToPro(settings: settings, in: modelContext)
                } else {
                    subscriptionSession.showAlert(String(localized: "subscription.restoreEmpty"))
                }
            }
        } errorCallback: { _ in
            Task { @MainActor in
                subscriptionSession.hideLoader()
            }
        }
    }
}
