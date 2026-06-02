import SwiftUI
import SwiftData

struct MainTabView: View {
    private let tabTint = Color(red: 0.05, green: 0.30, blue: 0.40)

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
        .tint(tabTint)
    }
}

#Preview {
    MainTabView()
        .modelContainer(FoodPlannerSchema.previewContainer)
}
