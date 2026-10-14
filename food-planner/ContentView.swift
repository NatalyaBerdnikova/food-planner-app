import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var isDatabaseReady = false
    @State private var importCoordinator = ImportCoordinator()

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    private var settings: AppSettings? { settingsList.first }

    private var hasCompletedOnboarding: Bool {
        settings?.hasCompletedOnboarding == true
    }

    var body: some View {
        @Bindable var subscriptionSession = subscriptionSession

        Group {
            if isDatabaseReady {
                gatedRoot
                    .environment(importCoordinator)
                    .applyAppLanguage(appLanguage)
            } else {
                ZStack {
                    AppTheme.heroGradient.ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
        }
        .task {
            await bootstrapIfNeeded()
            isDatabaseReady = true
        }
        .alert(
            subscriptionSession.alertText,
            isPresented: $subscriptionSession.alertPresented
        ) {
            Button("common.done", role: .cancel) {}
        }
        .overlay {
            if subscriptionSession.loaderPresented {
                SubscriptionLoader()
            }
        }
    }

    @ViewBuilder
    private var gatedRoot: some View {
        if !hasCompletedOnboarding {
            OnboardingFlowView {
                refreshSubscriptionStatus()
            }
        } else if !subscriptionSession.hasFullAccess {
            HardPaywallView()
        } else {
            mainApp
        }
    }

    private var mainApp: some View {
        MainTabView()
            .tint(AppTheme.accent)
            .task {
                importCoordinator.attach(modelContext: modelContext)
                FoodCatalogSeeder.seedIfNeeded(in: modelContext)
                RecipeCatalogStore.seedIfNeeded(in: modelContext)
                _ = AppSettingsService.settings(in: modelContext)
                importCoordinator.checkPendingImport()
            }
            .onOpenURL { url in
                importCoordinator.attach(modelContext: modelContext)
                importCoordinator.handleOpenURL(url)
            }
            .sheet(item: $importCoordinator.progressPresentation) { _ in
                ImportProgressView(coordinator: importCoordinator)
            }
            .sheet(item: $importCoordinator.editingDraft, onDismiss: {
                importCoordinator.clearDraft()
            }) { draft in
                NavigationStack {
                    ImportedRecipeReviewView(draft: draft)
                }
            }
    }

    private func bootstrapIfNeeded() async {
        await Task.yield()
        await FoodCatalogSeeder.seedIfNeeded(in: modelContext)
        await RecipeCatalogStore.seedIfNeeded(in: modelContext)
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.load(from: settings)
        refreshSubscriptionStatus()
    }

    private func refreshSubscriptionStatus() {
        PurchaseService.checkAccess { isPro in
            Task { @MainActor in
                subscriptionSession.isPro = isPro
                let settings = AppSettingsService.settings(in: modelContext)
                subscriptionSession.persist(to: settings, in: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(SubscriptionSession())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
