import SwiftUI
import SwiftData

struct RecipeLibraryView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var showAddRecipe = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        Group {
            if recipes.isEmpty {
                ContentUnavailableView(
                    "Нет рецептов",
                    systemImage: "book.closed",
                    description: Text("Создайте первый рецепт")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(recipes) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe)
                            } label: {
                                RecipeCardView(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Рецепты")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddRecipe = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Добавить рецепт")
            }
        }
        .navigationDestination(isPresented: $showAddRecipe) {
            AddRecipeView()
        }
    }
}
