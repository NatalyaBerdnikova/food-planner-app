import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var isBootstrapReady = false
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
            if isBootstrapReady && subscriptionSession.isAccessResolved {
                gatedRoot
                    .environment(importCoordinator)
                    .applyAppLanguage(appLanguage)
            } else {
                ZStack {
                    AppTheme.heroGradient.ignoresSafeArea()
                    SparklesLoader(tint: .white)
                }
            }
        }
        .task {
            await bootstrapIfNeeded()
        }
        .onAppear {
            bindProfileAccessUpdates()
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
                Task {
                    await refreshSubscriptionStatus()
                }
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
        await refreshSubscriptionStatus()
        isBootstrapReady = true
    }

    private func refreshSubscriptionStatus() async {
        let result = await PurchaseService.checkAccessWithRetry()
        subscriptionSession.applyAccessCheck(result)
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.persist(to: settings, in: modelContext)
    }

    private func bindProfileAccessUpdates() {
        let session = subscriptionSession
        let context = modelContext
        PurchaseService.onProfileAccessChanged = { isPro in
            session.isPro = isPro
            session.isAccessResolved = true
            let settings = AppSettingsService.settings(in: context)
            session.persist(to: settings, in: context)
        }
    }
}

#Preview {
    ContentView()
        .environment(SubscriptionSession())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
