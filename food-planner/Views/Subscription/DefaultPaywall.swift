import SwiftUI
import Adapty
import SwiftData

enum PaywallChrome {
    case standard
    case onHero
}

private struct PaywallPlanOption: Identifiable, Equatable {
    let id: String
    let title: String
    let price: String
    var periodLabel: String? = nil
    var subtitle: String? = nil
    var badge: String? = nil
    var includesTrial: Bool = false
}

struct DefaultPaywall: View {
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Environment(\.modelContext) private var modelContext

    let placement: Placements
    var chrome: PaywallChrome = .standard
    let successPurchaseCallback: () -> Void

    /// Temporary mock until Adapty products are wired for review.
    private let useMockPlans = true

    @State private var showPayment = false
    @State private var isLoadingPlans = true
    @State private var planOptions: [PaywallPlanOption] = []
    @State private var selectedPlanId: String?
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
        if useMockPlans {
            return planOptions.first { $0.id == selectedPlanId }?.includesTrial == true
        }
        guard let selectedProduct else { return false }
        return PurchaseService.hasTrial(product: selectedProduct, eligibilities: eligibilities)
    }

    private static let mockPlans: [PaywallPlanOption] = [
        PaywallPlanOption(
            id: "monthly",
            title: String(localized: "subscription.period.monthly"),
            price: "$9.99",
            periodLabel: String(localized: "subscription.plan.period.month"),
            subtitle: String(localized: "subscription.plan.monthly.subtitle")
        ),
        PaywallPlanOption(
            id: "annual",
            title: String(localized: "subscription.period.annual"),
            price: "$69.99",
            periodLabel: String(localized: "subscription.plan.period.year"),
            subtitle: String(localized: "subscription.plan.annual.subtitle"),
            badge: String(localized: "subscription.plan.badge.trial14"),
            includesTrial: true
        ),
        PaywallPlanOption(
            id: "lifetime",
            title: String(localized: "subscription.period.lifetime"),
            price: "$99.99",
            periodLabel: String(localized: "subscription.plan.period.once"),
            subtitle: String(localized: "subscription.plan.lifetime.subtitle"),
            badge: String(localized: "subscription.plan.badge.bestValue")
        ),
    ]

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

            if isLoadingPlans || haveRestoredSub {
                Spacer()
            }

            if !haveRestoredSub {
                VStack(alignment: .leading, spacing: 10) {
                    if isLoadingPlans {
                        SparklesLoader(tint: accentIcon)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        if !useMockPlans,
                           let trialDescription = eligibleProduct.flatMap({ SubscriptionProductDisplay.trialDescription(for: $0) }) {
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

                        ForEach(planOptions) { plan in
                            planRow(plan)
                        }
                    }
                }
                .padding(.top, 30)
            }

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                Button(action: startPayment) {
                    Text(haveRestoredSub ? "common.done" : (hasTrial ? "subscription.startTrial" : "subscription.startSubscribe"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.controlMinHeight)
                        .background(accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled((isLoadingPlans || selectedPlanId == nil) && !haveRestoredSub)

                if !haveRestoredSub {
                    Text(hasTrial ? "subscription.cta.trialHint" : "subscription.cta.subscribeHint")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)

            HStack(spacing: 12) {
                Link("subscription.terms", destination: URL(string: AppVars.termsUrl)!)
                Link("subscription.privacy", destination: URL(string: AppVars.privacyUrl)!)
                Button("subscription.restore", action: restorePayments)
            }
            .font(.caption.weight(.medium))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.bottom, 28)
            .foregroundStyle(secondaryText.opacity(0.9))
        }
        .padding(.horizontal, onHero ? 0 : 16)
        .padding(.vertical, onHero ? 0 : 16)
        .tint(accent)
        .onAppear {
            showPayment = true
            loadParams()
            if !useMockPlans {
                restorePaymentsOnLoad()
            }
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

    private func planRow(_ plan: PaywallPlanOption) -> some View {
        let isSelected = selectedPlanId == plan.id
        return Button {
            selectedPlanId = plan.id
            if !useMockPlans {
                selectedProduct = products.first { $0.vendorProductId == plan.id }
                hasTrialState = hasTrial
            }
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(plan.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(primaryText)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(accent.opacity(0.18), in: Capsule())
                        }
                    }

                    if let subtitle = plan.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(plan.price)
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(primaryText)
                    if let periodLabel = plan.periodLabel {
                        Text(periodLabel)
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? accent : secondaryText.opacity(0.65))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(onHero ? Color.white.opacity(isSelected ? 0.2 : 0.1) : Color.secondary.opacity(isSelected ? 0.16 : 0.08))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? accent.opacity(0.9) : Color.white.opacity(onHero ? 0.12 : 0),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func startPayment() {
        if haveRestoredSub {
            successPurchaseCallback()
            return
        }

        if useMockPlans {
            guard selectedPlanId != nil else { return }
            subscriptionSession.showLoader()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                subscriptionSession.hideLoader()
                successPurchaseCallback()
            }
            return
        }

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
        if useMockPlans {
            successPurchaseCallback()
            return
        }

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
        if useMockPlans {
            isLoadingPlans = true
            planOptions = []
            selectedPlanId = nil
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                planOptions = Self.mockPlans
                selectedPlanId = Self.mockPlans.first(where: \.includesTrial)?.id
                    ?? Self.mockPlans.first?.id
                isLoadingPlans = false
            }
            return
        }

        isLoadingPlans = true
        PurchaseService.getPaywall(placement: placement) { paywall in
            PurchaseService.getProducts(paywall: paywall) { loadedProducts in
                Task { @MainActor in
                    await StoreKitProductCatalog.load(productIds: loadedProducts.map(\.vendorProductId))
                    products = loadedProducts
                    planOptions = loadedProducts.map { product in
                        PaywallPlanOption(
                            id: product.vendorProductId,
                            title: SubscriptionProductDisplay.title(for: product),
                            price: SubscriptionProductDisplay.price(for: product)
                        )
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
                                selectedPlanId = eligProduct.vendorProductId
                            } else {
                                selectedProduct = loadedProducts.last
                                selectedPlanId = loadedProducts.last?.vendorProductId
                            }

                            hasTrialState = hasTrial
                            trialStateDisabled = !PurchaseService.canToggleTrial(loadedEligibilities)
                            isLoadingPlans = false
                        }
                    }
                }
            }
        } errorCallback: { error in
            Task { @MainActor in
                isLoadingPlans = false
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
        selectedPlanId = selectedProduct?.vendorProductId
    }
}
