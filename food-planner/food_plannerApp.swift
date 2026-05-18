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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(FoodPlannerSchema.container)
    }
}
