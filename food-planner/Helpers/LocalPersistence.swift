import Foundation
import SwiftData

enum LocalPersistence {
    /// Явно сохраняет все изменения SwiftData на диск устройства.
    @MainActor
    @discardableResult
    static func save(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            assertionFailure("LocalPersistence.save failed: \(error)")
            return false
        }
    }

    static var storeURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appending(path: "FoodPlanner.store", directoryHint: .notDirectory)
    }

    /// Удаляет локальный store SwiftData (после неудачной миграции схемы).
    static func removeStore() {
        let path = storeURL.path
        let fileManager = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            try? fileManager.removeItem(atPath: path + suffix)
        }
    }
}
