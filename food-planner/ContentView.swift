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
    @EnvironmentObject private var subscriptionSession: SubscriptionSession
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage(AppColorScheme.storageKey) private var appColorSchemeRaw = AppColorScheme.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    private var appColorScheme: AppColorScheme {
        AppColorScheme(rawValue: appColorSchemeRaw) ?? .system
    }

    var body: some View {
        ZStack {
            MainTabView()
                .applyAppLanguage(appLanguage)
                .applyAppColorScheme(appColorScheme)

            SubscriptionLoader(isPresented: $subscriptionSession.loaderPresented)
        }
        .task {
            FoodCatalogSeeder.seedIfNeeded(in: modelContext)
            RecipeCatalogStore.seedIfNeeded(in: modelContext)
            let settings = AppSettingsService.settings(in: modelContext)
            subscriptionSession.load(from: settings)
            refreshSubscriptionStatus(settings: settings)
        }
        .alert(
            subscriptionSession.alertText,
            isPresented: $subscriptionSession.alertPresented
        ) {
            Button("common.done", role: .cancel) {}
        }
        .sheet(isPresented: $subscriptionSession.paymentPresented) {
            PaymentModalView()
                .environmentObject(subscriptionSession)
        }
    }

    private func refreshSubscriptionStatus(settings: AppSettings) {
        PurchaseService.checkAccess { isPro in
            subscriptionSession.isPro = isPro
            subscriptionSession.persist(to: settings, in: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionSession())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
