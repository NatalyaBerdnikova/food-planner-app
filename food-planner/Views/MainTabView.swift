import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

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
    }
}

#Preview {
    MainTabView()
        .environment(ImportCoordinator())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
