import Foundation
import SwiftData

enum AppSettingsService {
    private static let singletonKey = "main"

    @MainActor
    static func settings(in context: ModelContext) -> AppSettings {
        let key = singletonKey
        var descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == key }
        )
        descriptor.fetchLimit = 1

        if let existing = fetchExisting(using: descriptor, in: context) {
            return existing
        }

        let settings = AppSettings()
        context.insert(settings)

        do {
            try context.save()
        } catch {
            if let existing = fetchExisting(using: descriptor, in: context) {
                return existing
            }
        }

        return settings
    }

    @MainActor
    static func setActiveWeekPlan(_ weekPlan: WeekPlan, in context: ModelContext) {
        let settings = settings(in: context)
        settings.activeWeekPlan = weekPlan
        LocalPersistence.save(context)
    }

    @MainActor
    private static func fetchExisting(
        using descriptor: FetchDescriptor<AppSettings>,
        in context: ModelContext
    ) -> AppSettings? {
        do {
            return try context.fetch(descriptor).first
        } catch {
            #if DEBUG
            print("AppSettingsService.fetch failed: \(error)")
            #endif
            return nil
        }
    }
}
