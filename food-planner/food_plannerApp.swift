import SwiftUI
import SwiftData

@main
struct food_plannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var subscriptionSession = SubscriptionSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptionSession)
        }
        .modelContainer(FoodPlannerSchema.container)
    }
}
