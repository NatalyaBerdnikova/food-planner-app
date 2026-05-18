//
//  ContentView.swift
//  food-planner
//
//  Created by Наталья Бердникова on 15.05.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    var body: some View {
        MainTabView()
            .applyAppLanguage(appLanguage)
            .onAppear {
                FoodCatalogSeeder.seedIfNeeded(in: modelContext)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(FoodPlannerSchema.previewContainer)
}
