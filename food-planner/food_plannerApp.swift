import SwiftUI
import SwiftData

@main
struct food_plannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(FoodPlannerSchema.container)
    }
}
