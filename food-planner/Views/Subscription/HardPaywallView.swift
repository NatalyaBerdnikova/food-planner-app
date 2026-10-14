import SwiftUI
import SwiftData

struct HardPaywallView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        ZStack {
            AppTheme.heroGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.warmFill)
                            .accessibilityHidden(true)

                        Text("paywall.hard.title")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("paywall.hard.subtitle")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    if let settings {
                        planSummaryCard(settings)
                    }

                    DefaultPaywall(
                        placement: .basic,
                        successPurchaseCallback: upgradeToPro,
                        successFreeCallback: upgradeToFree
                    )
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .interactiveDismissDisabled(true)
    }

    private func planSummaryCard(_ settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("paywall.hard.planReady")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                macroChip("\(Int(settings.targetCalories))", "kcal")
                macroChip("\(Int(settings.targetProtein))g", "P")
                macroChip("\(Int(settings.targetFat))g", "F")
                macroChip("\(Int(settings.targetCarbs))g", "C")
            }

            if !settings.profileMicronutrientFocus.isEmpty {
                Text("paywall.hard.micros")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(
                    settings.profileMicronutrientFocus
                        .prefix(4)
                        .map(\.displayName)
                        .joined(separator: " · ")
                )
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    private func macroChip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private func upgradeToPro() {
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.upgradeToPro(settings: settings, in: modelContext)
    }

    private func upgradeToFree() {
        let settings = AppSettingsService.settings(in: modelContext)
        subscriptionSession.upgradeToFree(settings: settings, in: modelContext)
    }
}
