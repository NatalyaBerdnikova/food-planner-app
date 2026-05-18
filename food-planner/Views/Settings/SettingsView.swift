import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("openAIAPIKey") private var apiKey = ""
    @AppStorage("productDatabaseName") private var productDatabaseName = ""
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @Query private var foodProducts: [FoodProduct]

    var body: some View {
        Form {
            Section {
                Picker("settings.language", selection: $appLanguageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName)
                            .tag(language.rawValue)
                    }
                }
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
    }
}
