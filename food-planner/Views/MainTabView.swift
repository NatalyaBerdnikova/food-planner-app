import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation

        TabView(selection: $navigation.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("tab.today", systemImage: "sun.max.fill")
            }
            .tag(AppTab.today)

            NavigationStack {
                WeekPlanView()
            }
            .tabItem {
                Label("tab.plan", systemImage: "calendar")
            }
            .tag(AppTab.plan)

            NavigationStack {
                ShoppingListView()
            }
            .tabItem {
                Label("tab.shopping", systemImage: "cart.fill")
            }
            .tag(AppTab.shopping)

            NavigationStack {
                RecipeLibraryView()
            }
            .tabItem {
                Label("tab.recipes", systemImage: "book.fill")
            }
            .tag(AppTab.recipes)
        }
        .tint(AppTheme.accent(for: colorScheme, highContrast: colorSchemeContrast == .increased))
        .tabViewStyle(.sidebarAdaptable)
        .onAppear {
            CommunitySocialStatsService.refreshLikeCountsIfNeeded(in: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                CommunitySocialStatsService.refreshLikeCountsIfNeeded(in: modelContext)
                TrialEngagementNotifications.refreshFromAdapty()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(ImportCoordinator())
        .environment(WeekPlanGenerationCoordinator())
        .environment(WeekPlanTransferCoordinator())
        .environment(AppNavigation())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
