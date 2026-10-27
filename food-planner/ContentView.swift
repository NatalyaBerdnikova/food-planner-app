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
    @State private var weekPlanTransfer = WeekPlanTransferCoordinator()
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
        @Bindable var weekPlanTransfer = weekPlanTransfer

        Group {
            if isBootstrapReady && subscriptionSession.isAccessResolved {
                gatedRoot
                    .applyAppLanguage(appLanguage)
            } else {
                ZStack {
                    AppTheme.heroGradient.ignoresSafeArea()
                    SparklesLoader(tint: .white)
                }
            }
        }
        .environment(importCoordinator)
        .environment(weekPlanGeneration)
        .environment(weekPlanTransfer)
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
                .environment(importCoordinator)
                .appFormSheetPresentation()
        }
        .sheet(item: $importCoordinator.editingDraft, onDismiss: {
            importCoordinator.clearDraft()
        }) { draft in
            NavigationStack {
                ImportedRecipeReviewView(draft: draft)
            }
            .environment(importCoordinator)
            .appFormSheetPresentation()
        }
        .sheet(item: $weekPlanGeneration.progressPresentation) { _ in
            WeekPlanGenerationProgressView(coordinator: weekPlanGeneration)
                .environment(weekPlanGeneration)
                .appFormSheetPresentation()
        }
        .sheet(item: $weekPlanTransfer.exportPresentation, onDismiss: {
            weekPlanTransfer.dismissExport()
        }) { presentation in
            ExportWeekPlanSheet(presentation: presentation)
                .environment(weekPlanTransfer)
        }
        .sheet(item: $weekPlanTransfer.sharePresentation, onDismiss: {
            weekPlanTransfer.dismissShare()
        }) { presentation in
            ShareSheet(items: [presentation.fileURL])
        }
        .sheet(item: $weekPlanTransfer.importPresentation, onDismiss: {
            weekPlanTransfer.dismissImport()
        }) { presentation in
            ImportWeekPlanSheet(
                document: presentation.document,
                initialWeekStart: presentation.targetWeekStart
                    ?? Calendar.current.startOfWeek(for: .now)
            )
            .environment(weekPlanTransfer)
        }
        .alert(
            subscriptionSession.alertText,
            isPresented: $subscriptionSession.alertPresented
        ) {
            Button("common.done", role: .cancel) {}
        }
        .alert(
            "weekPlan.transfer.error.title",
            isPresented: $weekPlanTransfer.showsError,
            presenting: weekPlanTransfer.errorMessage
        ) { _ in
            Button("common.done", role: .cancel) {}
        } message: { message in
            Text(message)
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
                weekPlanTransfer.attach(modelContext: modelContext)
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
        weekPlanTransfer.attach(modelContext: modelContext)

        if let url = pendingOpenURL {
            pendingOpenURL = nil
            if weekPlanTransfer.handleOpenURL(url) {
                return
            }
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
