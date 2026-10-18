import Foundation
import SwiftData

enum CommunitySocialStatsService {
    private static let lastRefreshDayKey = "communitySocialStats.lastLikeRefreshDay"

    @MainActor
    static func refreshLikeCountsIfNeeded(in context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        if let last = UserDefaults.standard.object(forKey: lastRefreshDayKey) as? Date,
           calendar.isDate(last, inSameDayAs: today) {
            return
        }
        refreshLikeCounts(in: context)
        UserDefaults.standard.set(today, forKey: lastRefreshDayKey)
    }

    @MainActor
    static func refreshLikeCounts(in context: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        guard let recipes = try? context.fetch(descriptor), !recipes.isEmpty else { return }

        let favoriteIds = RecipeFavoritesService.favoriteIds(in: context)
        for recipe in recipes {
            guard !recipe.isUserCreated else { continue }
            let others = Int.random(in: 0...99)
            let mine: Int = {
                guard let key = RecipeFavoritesService.favoriteKey(for: recipe) else { return 0 }
                return favoriteIds.contains(key) ? 1 : 0
            }()
            recipe.communityLikeCount = others + mine
        }
        LocalPersistence.save(context)
    }
}
