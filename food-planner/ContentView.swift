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
    @AppStorage(AppColorScheme.storageKey) private var appColorSchemeRaw = AppColorScheme.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    private var appColorScheme: AppColorScheme {
        AppColorScheme(rawValue: appColorSchemeRaw) ?? .system
    }

    var body: some View {
        MainTabView()
            .applyAppLanguage(appLanguage)
            .applyAppColorScheme(appColorScheme)
            .onAppear {
                FoodCatalogSeeder.seedIfNeeded(in: modelContext)
                RecipeCatalogSeeder.seedIfNeeded(in: modelContext)
                _ = AppSettingsService.settings(in: modelContext)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(FoodPlannerSchema.previewContainer)
}
