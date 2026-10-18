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
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
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
            .padding(AppTheme.contentPadding)
        }
        .appScreenBackground()
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
        Button {
            pasteImportRequest = PasteImportRequest()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "square.and.arrow.down.on.square.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.warmFill)
                            .motionSafeSymbolEffect(.pulse)
                            .accessibilityHidden(true)

                        Text("import.hero.title")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                    }

                    Text("import.hero.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("import.hero.shareHint")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxHeight: .infinity)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("import.hero.shareHint")
    }

    private var userRecipesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "recipeLibrary.myRecipes", systemImage: "person.crop.circle")

            LazyVGrid(columns: columns, spacing: 14) {
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
            AppSectionHeader(title: "home.recommendations", systemImage: "sparkles")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.sectionRailSpacing) {
                    ForEach(catalogRecipes) { recipe in
                        libraryCard(recipe)
                            .frame(width: AppTheme.recipeRailCardWidth)
                    }
                }
                .padding(.vertical, 2)
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
                RecipeCardView(recipe: recipe, style: .rail)
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

}
