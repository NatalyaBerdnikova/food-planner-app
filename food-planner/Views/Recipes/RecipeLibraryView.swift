import SwiftUI
import SwiftData

struct RecipeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var filterTab: RecipeFilterTab = .all
    @State private var showFavoritesOnly = false
    @State private var showMineOnly = false
    @State private var advancedFilters = RecipeAdvancedFilters()
    @State private var showAdvancedFilters = false
    @State private var pasteImportRequest: PasteImportRequest?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        AppTheme.recipeGridColumns(horizontalSizeClass: horizontalSizeClass)
    }

    private var favoriteIds: Set<String> {
        RecipeFavoritesService.favoriteIds(in: modelContext)
    }

    private var libraryRecipes: [Recipe] {
        RecipeCollections.libraryRecipes(from: recipes)
    }

    private var filteredRecipes: [Recipe] {
        var result = libraryRecipes

        if showMineOnly {
            result = result.filter(\.isUserCreated)
        }

        if showFavoritesOnly {
            result = RecipeFavoritesService.favoriteRecipes(from: result, favoriteIds: favoriteIds)
        }

        if let mealType = filterTab.mealType {
            result = result.filter { $0.matchesMealTypeFilter(mealType) }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { $0.matchesSearch(query) }
        }

        if advancedFilters.isActive {
            result = result.filter { advancedFilters.matches($0) }
        }

        return result
    }

    private var hasActiveQuickFilter: Bool {
        showFavoritesOnly
            || showMineOnly
            || filterTab != .all
            || advancedFilters.isActive
            || !searchText.isEmpty
    }

    private var emptyStateHint: String {
        hasActiveQuickFilter
            ? String(localized: "empty.recipesFiltered.hint")
            : String(localized: "empty.recipesLibrary.hint")
    }

    @ViewBuilder
    private var emptyState: some View {
        if hasActiveQuickFilter {
            ContentUnavailableView {
                Label("empty.recipesFiltered", systemImage: "magnifyingglass")
            } description: {
                Text(emptyStateHint)
            } actions: {
                Button("recipeLibrary.resetFilters") {
                    resetFilters()
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .controlSize(.regular)
            }
        } else {
            ContentUnavailableView(
                "empty.recipesLibrary",
                systemImage: "magnifyingglass",
                description: Text(emptyStateHint)
            )
        }
    }

    private func resetFilters() {
        searchText = ""
        filterTab = .all
        showFavoritesOnly = false
        showMineOnly = false
        advancedFilters.reset()
    }

    var body: some View {
        ScrollView {
            if filteredRecipes.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    ForEach(filteredRecipes, id: \.persistentModelID) { recipe in
                        libraryCard(recipe)
                    }
                }
                .padding(AppTheme.contentPadding)
                .appWideReadableWidth()
            }
        }
        .appScreenBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            quickFiltersBar
        }
        .navigationTitle("nav.recipes")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "search.recipes"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    pasteImportRequest = PasteImportRequest()
                } label: {
                    AppTheme.instagramGradient
                        .mask {
                            Image("InstagramLogo")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(width: 20, height: 20)
                }
                .accessibilityLabel("accessibility.importRecipe")

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
                .appFormSheetPresentation()
        }
        .sheet(isPresented: $showAdvancedFilters) {
            RecipeAdvancedFiltersSheet(filters: $advancedFilters)
                .appFormSheetPresentation()
        }
    }

    private var quickFiltersBar: some View {
        HorizontalScrollPeekHint {
            HStack(spacing: 8) {
                ForEach(RecipeFilterTab.allCases) { tab in
                    filterChip(
                        title: tab.displayName,
                        isSelected: filterTab == tab
                    ) {
                        filterTab = tab
                    }
                }

                filterChip(
                    title: "filter.mine",
                    isSelected: showMineOnly,
                    systemImage: "person.fill"
                ) {
                    showMineOnly.toggle()
                }

                filterChip(
                    title: "filter.favorites",
                    isSelected: showFavoritesOnly,
                    systemImage: "heart.fill"
                ) {
                    showFavoritesOnly.toggle()
                }

                Button {
                    showAdvancedFilters = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("recipeLibrary.filters")
                        if advancedFilters.isActive {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                                .accessibilityHidden(true)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: AppTheme.minTapTarget)
                    .background(
                        advancedFilters.isActive
                            ? Color.accentColor.opacity(0.15)
                            : Color(.tertiarySystemFill)
                    )
                    .foregroundStyle(advancedFilters.isActive ? Color.accentColor : Color.primary)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("recipeLibrary.advancedFilters")
                .accessibilityValue(
                    Text(advancedFilters.isActive ? "accessibility.filtersActive" : "accessibility.filtersInactive")
                )
            }
            .padding(.horizontal, AppTheme.contentPadding)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevated)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func filterChip(
        title: LocalizedStringResource,
        isSelected: Bool,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: AppTheme.minTapTarget)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func libraryCard(_ recipe: Recipe) -> some View {
        let isFavorite = RecipeFavoritesService.isFavorite(recipe, in: modelContext)
        let canFavorite = RecipeFavoritesService.canFavorite(recipe)

        return ZStack(alignment: .topTrailing) {
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                RecipeCardView(
                    recipe: recipe,
                    style: .grid,
                    showsNutrition: true,
                    imageMeta: .libraryBottomLeading
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            if canFavorite {
                Button {
                    RecipeFavoritesService.setFavorite(recipe, favorite: !isFavorite, in: modelContext)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isFavorite ? .red : .primary)
                        .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                        .background(AppTheme.contentOverlayFill, in: Circle())
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
}
