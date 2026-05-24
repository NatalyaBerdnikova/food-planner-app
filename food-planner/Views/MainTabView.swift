import SwiftUI
import SwiftData

struct MainTabView: View {
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
    }
}

#Preview {
    MainTabView()
        .modelContainer(FoodPlannerSchema.previewContainer)
}
