import SwiftUI
import SwiftData

@main
struct food_plannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var subscriptionSession = SubscriptionSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionSession)
        }
        .modelContainer(FoodPlannerSchema.container)
    }
}
