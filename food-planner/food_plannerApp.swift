import SwiftUI
import SwiftData

@main
struct food_plannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var subscriptionSession = SubscriptionSession()
    @State private var appNavigation = AppNavigation()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptionSession)
                .environment(appNavigation)
        }
        .modelContainer(FoodPlannerSchema.container)
    }
}
