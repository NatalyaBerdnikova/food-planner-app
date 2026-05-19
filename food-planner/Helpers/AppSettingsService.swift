import Foundation
import SwiftData

enum AppSettingsService {
    @MainActor
    static func settings(in context: ModelContext) -> AppSettings {
        var descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "main" }
        )
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let settings = AppSettings()
        context.insert(settings)
        LocalPersistence.save(context)
        return settings
    }

    @MainActor
    static func setActiveWeekPlan(_ weekPlan: WeekPlan, in context: ModelContext) {
        let settings = settings(in: context)
        settings.activeWeekPlan = weekPlan
        LocalPersistence.save(context)
    }
}
