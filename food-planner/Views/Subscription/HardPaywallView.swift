import SwiftUI
import SwiftData
import UIKit

struct HardPaywallView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        ZStack {
            paywallBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        BlinkingLockIcon(size: 44, tint: AppTheme.accent)

                        Text("paywall.hard.title")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    if let settings {
                        planSummary(settings)
                    }

                    Text("paywall.hard.subtitle")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)

                    DefaultPaywall(
                        placement: .basic,
                        chrome: .onHero,
                        successPurchaseCallback: upgradeToPro
                    )
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .appFormWidth()
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(true)
    }

    private var paywallBackground: some View {
        ZStack {
            if UIImage(named: "PaywallHero") != nil {
                Image("PaywallHero")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } else {
                AppTheme.heroGradient
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.45),
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.82),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func planSummary(_ settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("paywall.hard.planReady")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 8) {
                macroChip("nutrition.macro.kcal.full", value: "\(Int(settings.targetCalories))")
                macroChip("nutrition.macro.protein.full", value: "\(Int(settings.targetProtein))g")
                macroChip("nutrition.macro.fat.full", value: "\(Int(settings.targetFat))g")
                macroChip("nutrition.macro.carbs.full", value: "\(Int(settings.targetCarbs))g")
            }

            if !settings.profileMicronutrientFocus.isEmpty {
                VStack(spacing: 4) {
                    Text("paywall.hard.micros")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(
                        settings.profileMicronutrientFocus
                            .prefix(4)
                            .map(\.displayName)
                            .joined(separator: " · ")
                    )
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .fill(Color.black.opacity(0.12))
                }
        }
    }

    private func macroChip(_ title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func upgradeToPro() {
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.upgradeToPro(settings: settings, in: modelContext)
    }
}

#Preview("Paywall") {
    HardPaywallView()
        .environment(SubscriptionSession())
        .modelContainer(FoodPlannerSchema.previewContainer)
}
