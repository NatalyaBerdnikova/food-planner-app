import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("tab.today", systemImage: "sun.max.fill")
            }

            NavigationStack {
                WeekPlanView()
            }
            .tabItem {
                Label("tab.plan", systemImage: "calendar")
            }

            NavigationStack {
                ShoppingListView()
            }
            .tabItem {
                Label("tab.shopping", systemImage: "cart.fill")
            }

            NavigationStack {
                RecipeLibraryView()
            }
            .tabItem {
                Label("tab.recipes", systemImage: "book.fill")
            }
        }
        .tint(AppTheme.accent(for: colorScheme, highContrast: colorSchemeContrast == .increased))
        .tabViewStyle(.sidebarAdaptable)
        .onAppear {
            CommunitySocialStatsService.refreshLikeCountsIfNeeded(in: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                CommunitySocialStatsService.refreshLikeCountsIfNeeded(in: modelContext)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(ImportCoordinator())
        .environment(WeekPlanGenerationCoordinator())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
