import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage(AppColorScheme.storageKey) private var appColorSchemeRaw = AppColorScheme.system.rawValue

    @State private var importCoordinator = ImportCoordinator()

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    private var appColorScheme: AppColorScheme {
        AppColorScheme(rawValue: appColorSchemeRaw) ?? .system
    }

    var body: some View {
        MainTabView()
            .environment(importCoordinator)
            .applyAppLanguage(appLanguage)
            .applyAppColorScheme(appColorScheme)
            .task {
                ModelContextProvider.shared = modelContext
                FoodCatalogSeeder.seedIfNeeded(in: modelContext)
                RecipeCatalogStore.seedIfNeeded(in: modelContext)
                _ = AppSettingsService.settings(in: modelContext)
                importCoordinator.checkPendingImport()
            }
            .onOpenURL { url in
                importCoordinator.handleOpenURL(url)
            }
            .sheet(isPresented: $importCoordinator.showProgress) {
                ImportProgressView(coordinator: importCoordinator)
            }
            .sheet(item: $importCoordinator.editingDraft, onDismiss: {
                importCoordinator.importedDraft = nil
                importCoordinator.state = .idle
            }) { draft in
                NavigationStack {
                    AddRecipeView(prefill: draft)
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(FoodPlannerSchema.previewContainer)
}
