//
//  ContentView.swift
//  food-planner
//
//  Created by Наталья Бердникова on 15.05.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(FoodPlannerSchema.previewContainer)
}
