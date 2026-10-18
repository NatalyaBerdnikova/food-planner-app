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
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.accentSoft)
                            .accessibilityHidden(true)

                        Text("paywall.hard.title")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("paywall.hard.subtitle")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    if let settings {
                        planSummary(settings)
                    }

                    DefaultPaywall(
                        placement: .basic,
                        chrome: .onHero,
                        successPurchaseCallback: upgradeToPro
                    )
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .interactiveDismissDisabled(true)
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
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
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
