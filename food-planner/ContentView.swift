import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var isBootstrapReady = false
    @State private var importCoordinator = ImportCoordinator()
    @State private var weekPlanGeneration = WeekPlanGenerationCoordinator()
    @State private var pendingOpenURL: URL?

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    private var settings: AppSettings? { settingsList.first }

    private var hasCompletedOnboarding: Bool {
        settings?.hasCompletedOnboarding == true
    }

    private var canPresentImport: Bool {
        isBootstrapReady
            && subscriptionSession.isAccessResolved
            && hasCompletedOnboarding
            && subscriptionSession.hasFullAccess
    }

    var body: some View {
        @Bindable var subscriptionSession = subscriptionSession
        @Bindable var importCoordinator = importCoordinator
        @Bindable var weekPlanGeneration = weekPlanGeneration

        Group {
            if isBootstrapReady && subscriptionSession.isAccessResolved {
                gatedRoot
                    .environment(importCoordinator)
                    .environment(weekPlanGeneration)
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
            processPendingImportIfNeeded()
        }
        .onAppear {
            bindProfileAccessUpdates()
        }
        .onChange(of: canPresentImport) { _, isReady in
            if isReady {
                processPendingImportIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                processPendingImportIfNeeded()
            }
        }
        .onOpenURL { url in
            pendingOpenURL = url
            processPendingImportIfNeeded()
        }
        .sheet(item: $importCoordinator.progressPresentation) { _ in
            ImportProgressView(coordinator: importCoordinator)
                .appFormSheetPresentation()
        }
        .sheet(item: $importCoordinator.editingDraft, onDismiss: {
            importCoordinator.clearDraft()
        }) { draft in
            NavigationStack {
                ImportedRecipeReviewView(draft: draft)
            }
            .appFormSheetPresentation()
        }
        .sheet(item: $weekPlanGeneration.progressPresentation) { _ in
            WeekPlanGenerationProgressView(coordinator: weekPlanGeneration)
                .appFormSheetPresentation()
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
                weekPlanGeneration.attach(modelContext: modelContext)
                FoodCatalogSeeder.seedIfNeeded(in: modelContext)
                RecipeCatalogStore.seedIfNeeded(in: modelContext)
                _ = AppSettingsService.settings(in: modelContext)
                processPendingImportIfNeeded()
                weekPlanGeneration.startPendingGenerationIfNeeded()
            }
    }

    private func processPendingImportIfNeeded() {
        guard canPresentImport else { return }
        importCoordinator.attach(modelContext: modelContext)

        if let url = pendingOpenURL {
            pendingOpenURL = nil
            importCoordinator.handleOpenURL(url)
            return
        }

        importCoordinator.checkPendingImport()
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
