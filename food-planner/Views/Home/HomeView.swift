import SwiftUI
import SwiftData
import StoreKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(ImportCoordinator.self) private var importCoordinator
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var isTodayExpanded = false
    @State private var addMealPresentation: AddMealPresentation?
    @State private var pasteImportRequest: PasteImportRequest?
    @State private var featuredRecipeOverride: Recipe?
    @State private var surpriseNonce = 0

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]

    private var appSettings: AppSettings? { settingsList.first }

    private var currentWeekPlan: WeekPlan? {
        WeekPlanService.findCurrentWeekPlan(in: weekPlans)
    }

    private var featuredRecipe: Recipe? {
        featuredRecipeOverride ?? RecipeDiscoveryService.recipeOfTheDay(from: recipes)
    }

    private var favoriteColumns: [GridItem] {
        AppTheme.recipeGridColumns(horizontalSizeClass: horizontalSizeClass)
    }

    private var favoriteRecipes: [Recipe] {
        RecipeFavoritesService.favoriteRecipes(
            from: recipes,
            favoriteIds: Set(appSettings?.favoriteCatalogRecipeIds ?? [])
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                recipeOfTheDaySection
                importCTACard
                todayNutritionCard
                todayMealsSection
                favoritesSection
            }
            .padding(AppTheme.contentPadding)
            .appReadableWidth()
        }
        .appScreenBackground()
        .navigationTitle("nav.today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("accessibility.settings")
            }
        }
        .onAppear { refresh() }
        .motionSafeAnimation(.easeInOut(duration: 0.25), value: isTodayExpanded)
        .sheet(item: $addMealPresentation) { item in
            AddMealSheet(dayPlan: item.dayPlan, preferredMealType: item.mealType) {
                refresh()
            }
            .appFormSheetPresentation()
        }
        .sheet(item: $pasteImportRequest) { _ in
            PasteImportSheet()
                .appFormSheetPresentation()
        }
    }

    @ViewBuilder
    private var recipeOfTheDaySection: some View {
        if let recipe = featuredRecipe {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    AppSectionHeader(title: "home.recipeOfTheDay", systemImage: "sun.max.fill", fillsWidth: false)
                    Spacer(minLength: 0)
                    Button {
                        surpriseNonce &+= 1
                        let next = RecipeDiscoveryService.randomRecipe(
                            from: catalogRecipes.isEmpty ? recipes : catalogRecipes,
                            excluding: recipe.persistentModelID
                        )
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.32)) {
                            featuredRecipeOverride = next
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "shuffle")
                                .symbolRenderingMode(.hierarchical)
                                .modifier(SurpriseShuffleSymbolModifier(trigger: surpriseNonce))
                            Text("home.randomRecipe")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.accentSoft, in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(AppTheme.accent.opacity(0.28), lineWidth: 1)
                        }
                        .contentShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(SurpriseMeButtonStyle())
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.75), trigger: surpriseNonce)
                    .accessibilityHint("home.randomRecipe")
                }

                ZStack(alignment: .topTrailing) {
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeCardView(recipe: recipe, style: .hero, showsCommunityLikes: true)
                            .id(recipe.persistentModelID)
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                        removal: .opacity
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    if RecipeFavoritesService.canFavorite(recipe) {
                        let isFavorite = RecipeFavoritesService.isFavorite(recipe, in: modelContext)
                        Button {
                            toggleFavorite(for: recipe)
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
    }

    private var importCTACard: some View {
        Button {
            pasteImportRequest = PasteImportRequest()
        } label: {
            HStack(spacing: 14) {
                AppTheme.instagramGradient
                    .mask {
                        Image("InstagramLogo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 22, height: 22)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.instagramGradient)
                            .opacity(0.12)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("home.import.cta.title")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("home.import.cta.subtitle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppTheme.instagramGradient)
                    .frame(width: 3)
                    .padding(.vertical, 12)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("home.import.cta.title")
        .accessibilityHint("home.import.cta.subtitle")
    }

    private var todayNutritionCard: some View {
        AppSectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        isTodayExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        AppSectionHeader(title: "home.today", systemImage: "chart.bar.fill", fillsWidth: false)
                        if isTodayExpanded {
                            Text("home.targetProgress")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: isTodayExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("home.today")
                .accessibilityValue(Text(isTodayExpanded ? "accessibility.expanded" : "accessibility.collapsed"))
                .accessibilityHint("home.targetProgress")
                .accessibilityAddTraits(.isButton)

                if isTodayExpanded {
                    if let settings = appSettings {
                        NutritionTargetProgressView(
                            actual: todayNutrition,
                            target: settings.targetNutrition,
                            macroLabelStyle: .full,
                            embedded: true,
                            showsHeader: false
                        )
                    }
                } else {
                    NutritionSummaryView(
                        nutrition: todayNutrition,
                        target: appSettings?.targetNutrition,
                        embedded: true,
                        macroLabelStyle: .full
                    )
                }
            }
        }
    }

    private var todayMealsSection: some View {
        VStack(spacing: 10) {
            ForEach(dayMealTypes, id: \.self) { type in
                PlannedMealSlotView(
                    mealType: type,
                    meals: meals(for: type),
                    onTap: { presentAddMeal(for: type) },
                    style: .home
                )
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "home.favorites", systemImage: "heart.fill")

            if favoriteRecipes.isEmpty {
                ContentUnavailableView(
                    "home.favorites.empty",
                    systemImage: "heart",
                    description: Text("home.favorites.empty.hint")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: favoriteColumns, alignment: .center, spacing: 12) {
                    ForEach(favoriteRecipes, id: \.persistentModelID) { recipe in
                        favoriteCard(recipe)
                    }
                }
            }
        }
    }

    private func favoriteCard(_ recipe: Recipe) -> some View {
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
                    toggleFavorite(for: recipe)
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

    private func toggleFavorite(for recipe: Recipe) {
        let isFavorite = RecipeFavoritesService.isFavorite(recipe, in: modelContext)
        let becameFavorite = RecipeFavoritesService.setFavorite(
            recipe,
            favorite: !isFavorite,
            in: modelContext
        )
        if becameFavorite {
            ReviewPromptService.considerAfterRecipeAppreciation(
                requestReview,
                hasFullAccess: subscriptionSession.hasFullAccess
            )
        }
    }

    private var catalogRecipes: [Recipe] {
        RecipeCollections.catalogRecipes(from: recipes)
    }

    private var todayDayPlan: DayPlan? {
        guard let weekPlan = currentWeekPlan else { return nil }
        let calendar = Calendar.current
        return weekPlan.dayPlans.first { calendar.isDateInToday($0.date) }
    }

    private var todayNutrition: DailyNutrition {
        guard let dayPlan = todayDayPlan else { return .zero }
        return NutritionCalculator.from(dayPlan: dayPlan)
    }

    private func meals(for type: MealType) -> [Meal] {
        todayDayPlan?.meals(for: type) ?? []
    }

    private func presentAddMeal(for mealType: MealType) {
        let dayPlan = WeekPlanService.todayDayPlan(from: weekPlans, in: modelContext)
        addMealPresentation = AddMealPresentation(dayPlan: dayPlan, mealType: mealType)
    }

    private func refresh() {
        let plan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        AppSettingsService.setActiveWeekPlan(plan, in: modelContext)
        _ = WeekPlanService.todayDayPlan(from: weekPlans, in: modelContext)
    }
}

private struct SurpriseMeButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect((!reduceMotion && configuration.isPressed) ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72),
                value: configuration.isPressed
            )
    }
}

private struct SurpriseShuffleSymbolModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Int

    func body(content: Content) -> some View {
        Group {
            if reduceMotion {
                content
            } else {
                content.symbolEffect(.bounce, value: trigger)
            }
        }
    }
}
