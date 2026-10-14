import SwiftUI
import SwiftData

struct RecipeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImportCoordinator.self) private var importCoordinator
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var pasteImportRequest: PasteImportRequest?
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                importHero

                if userRecipes.isEmpty && catalogRecipes.isEmpty {
                    ContentUnavailableView(
                        "empty.recipesLibrary",
                        systemImage: "book.closed",
                        description: Text("empty.recipesLibrary.hint")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    if !userRecipes.isEmpty {
                        userRecipesSection
                    }
                    if !catalogRecipes.isEmpty {
                        recommendationsSection
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("nav.recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddRecipeView()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("accessibility.addRecipe")
            }
        }
        .sheet(item: $pasteImportRequest) { _ in
            PasteImportSheet()
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

    private var importHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.warmFill)
                    .motionSafeSymbolEffect(.pulse)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("import.hero.title")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("import.hero.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 10) {
                Button {
                    pasteImportRequest = PasteImportRequest()
                } label: {
                    Label("import.hero.paste", systemImage: "link")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.controlMinHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.warmFill)
                .foregroundStyle(.black)

                Button {
                    openInstagram()
                } label: {
                    Label("import.hero.openInstagram", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.controlMinHeight)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }

            Text("import.hero.shareHint")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var userRecipesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("recipeLibrary.myRecipes")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(userRecipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeCardView(recipe: recipe, badge: .userCreated)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("home.recommendations")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(catalogRecipes) { recipe in
                    libraryCard(recipe)
                }
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
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

    private func openInstagram() {
        if let url = URL(string: "instagram://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let web = URL(string: "https://www.instagram.com") {
            UIApplication.shared.open(web)
        }
    }
}
