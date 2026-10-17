import Foundation
import SwiftData

enum CommunitySocialStatsService {
    @MainActor
    static func refreshLikeCounts(in context: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        guard let recipes = try? context.fetch(descriptor), !recipes.isEmpty else { return }

        for recipe in recipes {
            recipe.communityLikeCount = Int.random(in: 0...100)
        }
        LocalPersistence.save(context)
    }
}
