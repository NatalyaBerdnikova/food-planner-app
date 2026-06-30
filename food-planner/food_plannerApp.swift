//
//  food_plannerApp.swift
//  food-planner
//
//  Created by Наталья Бердникова on 15.05.2026.
//

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
