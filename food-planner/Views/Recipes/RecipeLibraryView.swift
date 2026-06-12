import SwiftUI
import SwiftData

struct RecipeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var showAddRecipe = false
    @State private var unfavoriteCandidate: Recipe?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    private var favoriteIds: Set<String> {
        Set(settingsList.first?.favoriteCatalogRecipeIds ?? [])
    }

    private var libraryRecipes: [Recipe] {
        RecipeCollections.libraryRecipes(from: recipes, favoriteIds: favoriteIds)
    }

    var body: some View {
        Group {
            if libraryRecipes.isEmpty {
                ContentUnavailableView(
                    "empty.recipesLibrary",
                    systemImage: "book.closed",
                    description: Text("empty.recipesLibrary.hint")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(libraryRecipes) { recipe in
                            libraryCard(recipe)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("nav.recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddRecipe = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("accessibility.addRecipe")
            }
        }
        .navigationDestination(isPresented: $showAddRecipe) {
            AddRecipeView()
        }
        .alert(
            "favorites.remove.title",
            isPresented: Binding(
                get: { unfavoriteCandidate != nil },
                set: { if !$0 { unfavoriteCandidate = nil } }
            )
        ) {
            Button("common.cancel", role: .cancel) {
                unfavoriteCandidate = nil
            }
            Button("favorites.remove.confirm", role: .destructive) {
                if let recipe = unfavoriteCandidate {
                    RecipeFavoritesService.setFavorite(recipe, favorite: false, in: modelContext)
                }
                unfavoriteCandidate = nil
            }
        } message: {
            if let recipe = unfavoriteCandidate {
                Text("favorites.remove.message \(recipe.name)")
            }
        }
    }

    private func libraryCard(_ recipe: Recipe) -> some View {
        let isFavorite = recipe.isCatalogRecipe
            && RecipeFavoritesService.isFavorite(recipe, in: modelContext)

        return ZStack(alignment: .topTrailing) {
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                RecipeCardView(recipe: recipe)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            if recipe.isUserCreated {
                Image(systemName: "person.crop.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(6)
                    .accessibilityLabel("accessibility.userRecipe")
            } else if isFavorite {
                Button {
                    unfavoriteCandidate = recipe
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
                .accessibilityLabel("accessibility.removeFavorite")
            }
        }
    }
}
