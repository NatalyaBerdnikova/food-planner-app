import SwiftUI
import Adapty
import SwiftData

struct DefaultPaywall: View {
    @EnvironmentObject private var subscriptionSession: SubscriptionSession
    @Environment(\.modelContext) private var modelContext

    let placement: Placements
    let successPurchaseCallback: () -> Void
    let successFreeCallback: () -> Void

    @State private var showPayment = false
    @State private var products: [AdaptyPaywallProduct] = []
    @State private var eligibilities: [String: AdaptyEligibility] = [:]
    @State private var selectedProduct: AdaptyPaywallProduct?
    @State private var eligibleProduct: AdaptyPaywallProduct?
    @State private var haveRestoredSub = false
    @State private var hasTrialState = false
    @State private var trialStateDisabled = true

    private let accentTeal = Color(red: 0.06, green: 0.33, blue: 0.45)

    private var hasTrial: Bool {
        guard let selectedProduct else { return false }
        return PurchaseService.hasTrial(product: selectedProduct, eligibilities: eligibilities)
    }

    var body: some View {
        VStack {
            VStack {
                Text("home.proOffer.bannerTitle")
                    .multilineTextAlignment(.center)
                    .font(.title.bold())
                    .opacity(showPayment ? 1 : 0)
                    .scaleEffect(showPayment ? 1 : 0.6)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: showPayment)

                VStack(alignment: .leading, spacing: 15) {
                    featureRow(icon: "wand.and.stars", text: "home.proOffer.feature.ai")
                    featureRow(icon: "chart.line.uptrend.xyaxis", text: "home.proOffer.feature.insights")
                    featureRow(icon: "calendar.badge.clock", text: "home.proOffer.feature.plan")
                }
                .font(.title3.bold())
                .padding(.top)
                .opacity(showPayment ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: showPayment)
            }

            if haveRestoredSub {
                Spacer()
                Text("subscription.alreadyActive")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .foregroundStyle(accentTeal)
                    .padding()
            }

            if products.isEmpty || haveRestoredSub {
                Spacer()
            }

            if !haveRestoredSub {
                VStack(alignment: .leading, spacing: 15) {
                    if products.isEmpty {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(2)
                            .frame(maxWidth: .infinity)
                    } else {
                        if let trialDescription = eligibleProduct?.skProduct.localizedTrialDescription {
                            SubscriptionHContainer {
                                Toggle(isOn: Binding(
                                    get: { hasTrialState },
                                    set: { newValue in
                                        toggleTrialState(newValue)
                                        hasTrialState = newValue
                                    }
                                )) {
                                    Text("subscription.enableTrial \(trialDescription)")
                                        .font(.title3)
                                        .foregroundStyle(accentTeal)
                                }
                                .disabled(trialStateDisabled)
                            }
                        }

                        ForEach(products, id: \.vendorProductId) { product in
                            Button {
                                selectedProduct = product
                                hasTrialState = hasTrial
                            } label: {
                                SubscriptionHContainer {
                                    ZStack {
                                        Image(systemName: "circle")
                                            .foregroundStyle(accentTeal)
                                            .imageScale(.large)

                                        if selectedProduct?.vendorProductId == product.vendorProductId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(accentTeal)
                                                .imageScale(.large)
                                        }
                                    }

                                    Text(product.skProduct.title)
                                        .font(.title3)
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 5)

                                    Spacer()

                                    Text(product.skProduct.localizedPrice)
                                        .font(.title2)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(accentTeal, lineWidth: selectedProduct?.vendorProductId == product.vendorProductId ? 2 : 0)
                                        .opacity(0.5)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 30)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: startPayment) {
                    Text(haveRestoredSub ? "common.done" : (hasTrial ? "subscription.startTrial" : "subscription.startSubscribe"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 300, height: 50)
                        .background(accentTeal.opacity(0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(products.isEmpty && !haveRestoredSub)

                Button(action: startFree) {
                    Text("subscription.startFree")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 300, height: 50)
                        .background(Color.secondary.opacity(0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(.vertical, 30)

            HStack(alignment: .firstTextBaseline, spacing: 15) {
                Link("subscription.terms", destination: URL(string: AppVars.termsUrl)!)
                Link("subscription.privacy", destination: URL(string: AppVars.privacyUrl)!)
                Button("subscription.restore", action: restorePayments)
            }
            .padding(.bottom, 40)
            .foregroundStyle(.secondary)
            .opacity(0.8)
        }
        .padding()
        .tint(accentTeal)
        .onAppear {
            showPayment = true
            loadParams()
            restorePaymentsOnLoad()
        }
    }

    private func featureRow(icon: String, text: LocalizedStringResource) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(accentTeal)
                .imageScale(.large)
                .frame(width: 30)
            Text(text)
        }
    }

    private func startPayment() {
        subscriptionSession.showLoader()

        PurchaseService.restorePurchases { purchased in
            Task { @MainActor in
                if purchased {
                    subscriptionSession.hideLoader()
                    successPurchaseCallback()
                } else {
                    startPurchase()
                }
            }
        } errorCallback: { _ in
            Task { @MainActor in
                startPurchase()
            }
        }
    }

    private func startFree() {
        successFreeCallback()
    }

    private func startPurchase() {
        guard let selectedProduct else { return }

        subscriptionSession.showLoader()

        PurchaseService.makePurchase(product: selectedProduct) { _ in
            Task { @MainActor in
                successPurchaseCallback()
                subscriptionSession.hideLoader()
            }
        } errorCallback: { _ in
            Task { @MainActor in
                subscriptionSession.hideLoader()
                subscriptionSession.showAlert(String(localized: "subscription.purchaseError"))
            }
        }
    }

    private func restorePayments() {
        #if DEBUG
        successPurchaseCallback()
        return
        #endif

        subscriptionSession.showLoader()

        PurchaseService.restorePurchases { purchased in
            Task { @MainActor in
                subscriptionSession.hideLoader()

                if purchased {
                    successPurchaseCallback()
                } else {
                    subscriptionSession.showAlert(String(localized: "subscription.restoreEmpty"))
                }
            }
        } errorCallback: { _ in
            Task { @MainActor in
                subscriptionSession.hideLoader()
            }
        }
    }

    private func restorePaymentsOnLoad() {
        PurchaseService.restorePurchases { purchased in
            Task { @MainActor in
                if purchased {
                    haveRestoredSub = true
                }
            }
        } errorCallback: { _ in }
    }

    private func loadParams() {
        PurchaseService.getPaywall(placement: placement) { paywall in
            PurchaseService.getProducts(paywall: paywall) { loadedProducts in
                Task { @MainActor in
                    products = loadedProducts
                }

                PurchaseService.getEligibilities(products: loadedProducts) { loadedEligibilities in
                    Task { @MainActor in
                        eligibilities = loadedEligibilities
                        let eligProduct = PurchaseService.getFirstEligibleProduct(
                            products: loadedProducts,
                            eligibilities: loadedEligibilities
                        )

                        if let eligProduct {
                            selectedProduct = eligProduct
                            eligibleProduct = eligProduct
                        } else {
                            selectedProduct = loadedProducts.last
                        }

                        hasTrialState = hasTrial
                        trialStateDisabled = !PurchaseService.canToggleTrial(loadedEligibilities)
                    }
                }
            }
        } errorCallback: { error in
            Task { @MainActor in
                subscriptionSession.showAlert(error)
            }
        }
    }

    private func toggleTrialState(_ value: Bool) {
        if value {
            selectedProduct = products.first { $0.vendorProductId == eligibleProduct?.vendorProductId }
        } else {
            selectedProduct = products.last { $0.vendorProductId != eligibleProduct?.vendorProductId }
        }
    }
}
