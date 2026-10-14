import SwiftUI
import SwiftData

struct RecipeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImportCoordinator.self) private var importCoordinator
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var showAddRecipe = false
    @State private var unfavoriteCandidate: Recipe?

    #if DEBUG
    @State private var debugImportURL = ""
    #endif

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
        .background(Color(.systemGroupedBackground))
        #if DEBUG
        .safeAreaInset(edge: .bottom) {
            debugImportBar
        }
        #endif
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
                Text("favorites.remove.message \(recipe.localizedName)")
            }
        }
    }

    private var userRecipesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("recipeLibrary.myRecipes")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(userRecipes) { recipe in
                    userRecipeCard(recipe)
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("home.recommendations")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(catalogRecipes) { recipe in
                    recommendationCard(recipe)
                }
            }
        }
    }

    private func userRecipeCard(_ recipe: Recipe) -> some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe)
        } label: {
            RecipeCardView(recipe: recipe, badge: .userCreated)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("accessibility.userRecipe")
    }

    private func recommendationCard(_ recipe: Recipe) -> some View {
        let isFavorite = RecipeFavoritesService.isFavorite(recipe, in: modelContext)
    #if DEBUG
    private var debugImportBar: some View {
        HStack(spacing: 8) {
            TextField("import.debug.placeholder", text: $debugImportURL)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            Button("import.debug.button") {
                let url = debugImportURL.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !url.isEmpty else { return }
                importCoordinator.startImport(urlString: url)
            }
            .buttonStyle(.borderedProminent)
            .disabled(debugImportURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
    #endif

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
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(8)
            .accessibilityLabel(
                isFavorite
                    ? String(localized: "accessibility.removeFavorite")
                    : String(localized: "accessibility.addFavorite")
            )
        }
    }
}
