import SwiftUI
import SwiftData

struct PaymentModalView: View {
    @EnvironmentObject private var subscriptionSession: SubscriptionSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                DefaultPaywall(
                    placement: .basic,
                    successPurchaseCallback: upgradeUser,
                    successFreeCallback: upgradeUserToFree
                )
                .padding(.top)
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    private func upgradeUser() {
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.upgradeToPro(settings: settings, in: modelContext)
        dismiss()
    }

    private func upgradeUserToFree() {
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.upgradeToFree(settings: settings, in: modelContext)
        dismiss()
    }
}

struct PaywallView: View {
    @EnvironmentObject private var subscriptionSession: SubscriptionSession
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                DefaultPaywall(
                    placement: .basic,
                    successPurchaseCallback: upgradeUser,
                    successFreeCallback: upgradeUserToFree
                )
                .padding(.top)
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    private func upgradeUser() {
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.upgradeToPro(settings: settings, in: modelContext)
    }

    private func upgradeUserToFree() {
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.upgradeToFree(settings: settings, in: modelContext)
    }
}
