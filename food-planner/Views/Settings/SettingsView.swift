import SwiftUI

struct SettingsView: View {
    @AppStorage("openAIAPIKey") private var apiKey = ""
    @AppStorage("productDatabaseName") private var productDatabaseName = ""

    var body: some View {
        Form {
            Section {
                SecureField("API ключ", text: $apiKey)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("API")
            } footer: {
                Text("Ключ для генерации рецептов и подсказок (будет использоваться позже).")
            }

            Section {
                TextField("Название базы продуктов", text: $productDatabaseName)
            } header: {
                Text("База продуктов")
            } footer: {
                Text("Справочник продуктов для автозаполнения ингредиентов.")
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }
}
