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

    private var userRecipes: [Recipe] {
        RecipeCollections.userRecipes(from: recipes)
    }

    private var catalogRecipes: [Recipe] {
        RecipeCollections.sortedCatalogRecipes(from: recipes)
    }

    var body: some View {
        Group {
            if userRecipes.isEmpty && catalogRecipes.isEmpty {
                ContentUnavailableView(
                    "empty.recipesLibrary",
                    systemImage: "book.closed",
                    description: Text("empty.recipesLibrary.hint")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !userRecipes.isEmpty {
                            userRecipesSection
                        }

                        if !catalogRecipes.isEmpty {
                            recommendationsSection
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

    private var userRecipesSection: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(userRecipes) { recipe in
                userRecipeCard(recipe)
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("home.recommendations")
                .font(.title3.bold())
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(catalogRecipes) { recipe in
                    recommendationCard(recipe)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.33, blue: 0.45),
                    Color(red: 0.05, green: 0.22, blue: 0.33),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 4)
    }

    private func userRecipeCard(_ recipe: Recipe) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                RecipeCardView(recipe: recipe)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "person.crop.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .padding(6)
                .accessibilityLabel("accessibility.userRecipe")
        }
    }

    private func recommendationCard(_ recipe: Recipe) -> some View {
        let isFavorite = RecipeFavoritesService.isFavorite(recipe, in: modelContext)

        return ZStack(alignment: .topTrailing) {
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                RecipeCardView(recipe: recipe)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if isFavorite {
                    unfavoriteCandidate = recipe
                } else {
                    RecipeFavoritesService.setFavorite(recipe, favorite: true, in: modelContext)
                }
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isFavorite ? .red : .secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
            .accessibilityLabel(
                isFavorite
                    ? String(localized: "accessibility.removeFavorite")
                    : String(localized: "accessibility.addFavorite")
            )
        }
    }
}
