//
//  food_plannerApp.swift
//  food-planner
//
//  Created by Наталья Бердникова on 15.05.2026.
//

import SwiftUI
import SwiftData
import Adapty

@main
struct food_plannerApp: App {
    @StateObject private var subscriptionSession = SubscriptionSession()

    init() {
        Adapty.activate(AppVars.adaptyToken)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionSession)
        }
        .modelContainer(FoodPlannerSchema.container)
    }
}
