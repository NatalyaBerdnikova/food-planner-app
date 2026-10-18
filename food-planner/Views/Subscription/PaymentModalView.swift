import SwiftUI
import SwiftData

struct PaymentModalView: View {
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                DefaultPaywall(
                    placement: .basic,
                    successPurchaseCallback: upgradeUser
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
}

struct PaywallView: View {
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                DefaultPaywall(
                    placement: .basic,
                    successPurchaseCallback: upgradeUser
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
}
