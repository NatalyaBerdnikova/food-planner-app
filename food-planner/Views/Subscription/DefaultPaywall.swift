import SwiftUI
import Adapty
import SwiftData

enum PaywallChrome {
    case standard
    case onHero
}

struct DefaultPaywall: View {
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Environment(\.modelContext) private var modelContext

    let placement: Placements
    var chrome: PaywallChrome = .standard
    let successPurchaseCallback: () -> Void

    @State private var showPayment = false
    @State private var products: [AdaptyPaywallProduct] = []
    @State private var eligibilities: [String: AdaptyEligibility] = [:]
    @State private var selectedProduct: AdaptyPaywallProduct?
    @State private var eligibleProduct: AdaptyPaywallProduct?
    @State private var haveRestoredSub = false
    @State private var hasTrialState = false
    @State private var trialStateDisabled = true

    private let accent = AppTheme.accent
    private var onHero: Bool { chrome == .onHero }
    private var primaryText: Color { onHero ? .white : .primary }
    private var secondaryText: Color { onHero ? Color.white.opacity(0.85) : .secondary }
    private var accentIcon: Color { onHero ? AppTheme.accentSoft : accent }

    private var hasTrial: Bool {
        guard let selectedProduct else { return false }
        return PurchaseService.hasTrial(product: selectedProduct, eligibilities: eligibilities)
    }

    var body: some View {
        VStack {
            if !onHero {
                VStack {
                    Text("home.proOffer.bannerTitle")
                        .multilineTextAlignment(.center)
                        .font(.title.bold())
                        .foregroundStyle(primaryText)
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
            }

            if haveRestoredSub {
                Spacer()
                Text("subscription.alreadyActive")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .foregroundStyle(accentIcon)
                    .padding()
            }

            if products.isEmpty || haveRestoredSub {
                Spacer()
            }

            if !haveRestoredSub {
                VStack(alignment: .leading, spacing: 15) {
                    if products.isEmpty {
                        SparklesLoader(tint: accentIcon)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        if let trialDescription = eligibleProduct.flatMap({ SubscriptionProductDisplay.trialDescription(for: $0) }) {
                            SubscriptionHContainer(onHero: onHero) {
                                Toggle(isOn: Binding(
                                    get: { hasTrialState },
                                    set: { newValue in
                                        toggleTrialState(newValue)
                                        hasTrialState = newValue
                                    }
                                )) {
                                    Text("subscription.enableTrial \(trialDescription)")
                                        .font(.title3)
                                        .foregroundStyle(onHero ? primaryText : accent)
                                }
                                .tint(accent)
                                .disabled(trialStateDisabled)
                            }
                        }

                        ForEach(products, id: \.vendorProductId) { product in
                            Button {
                                selectedProduct = product
                                hasTrialState = hasTrial
                            } label: {
                                SubscriptionHContainer(onHero: onHero) {
                                    ZStack {
                                        Image(systemName: "circle")
                                            .foregroundStyle(accentIcon)
                                            .imageScale(.large)

                                        if selectedProduct?.vendorProductId == product.vendorProductId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(accentIcon)
                                                .imageScale(.large)
                                        }
                                    }

                                    Text(SubscriptionProductDisplay.title(for: product))
                                        .font(.title3)
                                        .foregroundStyle(primaryText)
                                        .padding(.horizontal, 5)

                                    Spacer()

                                    Text(SubscriptionProductDisplay.price(for: product))
                                        .font(.title2)
                                        .foregroundStyle(primaryText)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            accentIcon,
                                            lineWidth: selectedProduct?.vendorProductId == product.vendorProductId ? 2 : 0
                                        )
                                        .opacity(0.7)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 30)
            }

            Spacer()

            Button(action: startPayment) {
                Text(haveRestoredSub ? "common.done" : (hasTrial ? "subscription.startTrial" : "subscription.startSubscribe"))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(products.isEmpty && !haveRestoredSub)
            .padding(.vertical, 30)

            HStack(spacing: 12) {
                Link("subscription.terms", destination: URL(string: AppVars.termsUrl)!)
                Link("subscription.privacy", destination: URL(string: AppVars.privacyUrl)!)
                Button("subscription.restore", action: restorePayments)
            }
            .font(.footnote.weight(.medium))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.bottom, 40)
            .foregroundStyle(secondaryText)
        }
        .padding(.horizontal, onHero ? 0 : 16)
        .padding(.vertical, onHero ? 0 : 16)
        .tint(accent)
        .onAppear {
            showPayment = true
            loadParams()
            restorePaymentsOnLoad()
        }
    }

    private func featureRow(icon: String, text: LocalizedStringResource) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(accentIcon)
                .imageScale(.large)
                .frame(width: 30)
            Text(text)
                .foregroundStyle(primaryText)
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
                    await StoreKitProductCatalog.load(productIds: loadedProducts.map(\.vendorProductId))
                    products = loadedProducts

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
