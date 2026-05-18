import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Главная", systemImage: "house.fill")
            }

            NavigationStack {
                WeekPlanView()
            }
            .tabItem {
                Label("План", systemImage: "calendar")
            }

            NavigationStack {
                ShoppingListView()
            }
            .tabItem {
                Label("Покупки", systemImage: "cart.fill")
            }

            NavigationStack {
                RecipeLibraryView()
            }
            .tabItem {
                Label("Рецепты", systemImage: "book.fill")
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(FoodPlannerSchema.previewContainer)
}
