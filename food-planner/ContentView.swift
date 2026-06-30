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
    @State private var isDatabaseReady = false

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    private var appColorScheme: AppColorScheme {
        AppColorScheme(rawValue: appColorSchemeRaw) ?? .system
    }

    var body: some View {
        Group {
            if isDatabaseReady {
                MainTabView()
                    .applyAppLanguage(appLanguage)
                    .applyAppColorScheme(appColorScheme)
                    .overlay {
                        if subscriptionSession.loaderPresented {
                            SubscriptionLoader()
                        }
                    }
            } else {
                SubscriptionLoader()
            }
        }
        .task {
            await bootstrapIfNeeded()
            isDatabaseReady = true
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

    private func bootstrapIfNeeded() async {
        await Task.yield()
        await FoodCatalogSeeder.seedIfNeeded(in: modelContext)
        await RecipeCatalogStore.seedIfNeeded(in: modelContext)
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.load(from: settings)
        refreshSubscriptionStatus()
    }

    private func refreshSubscriptionStatus() {
        PurchaseService.checkAccess { isPro in
            Task { @MainActor in
                subscriptionSession.isPro = isPro
                let settings = AppSettingsService.settings(in: modelContext)
                subscriptionSession.persist(to: settings, in: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionSession())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
