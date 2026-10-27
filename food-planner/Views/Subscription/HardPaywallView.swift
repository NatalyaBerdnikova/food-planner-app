import SwiftUI
import SwiftData
import UIKit

struct HardPaywallView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionSession.self) private var subscriptionSession
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var showDayPreview = false
    @State private var previewDayPlan: DayPlan?

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
        .sheet(isPresented: $showDayPreview, onDismiss: discardPreviewDayPlan) {
            dayPreviewSheet
        }
    }

    @ViewBuilder
    private var dayPreviewSheet: some View {
        if let settings, let previewDayPlan {
            NavigationStack {
                ScrollView {
                    OnboardingDayPreviewStep(
                        dayPlan: previewDayPlan,
                        target: settings.targetNutrition,
                        micronutrientFocus: settings.profileMicronutrientFocus
                    )
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .appFormWidth()
                }
                .background(AppTheme.canvas.ignoresSafeArea())
                .navigationTitle("onboarding.dayPreview.title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("common.done") {
                            showDayPreview = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.light)
        }
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
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                macroChip("nutrition.macro.kcal.full", value: "\(Int(settings.targetCalories))")
                Spacer(minLength: 8)
                macroChip("nutrition.macro.protein.full", value: "\(Int(settings.targetProtein))g")
                Spacer(minLength: 8)
                macroChip("nutrition.macro.fat.full", value: "\(Int(settings.targetFat))g")
                Spacer(minLength: 8)
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

            Button(action: openDayPreview) {
                Text("onboarding.cta.dayPreview")
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("onboarding.dayPreview.title"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
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
        VStack(alignment: .center, spacing: 4) {
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
        .multilineTextAlignment(.center)
    }

    private func openDayPreview() {
        guard let settings else { return }
        previewDayPlan = OnboardingDayPreviewFactory.makeDayPlan(
            in: modelContext,
            matching: settings.targetNutrition,
            micronutrientFocus: settings.profileMicronutrientFocus
        )
        guard previewDayPlan != nil else { return }
        showDayPreview = true
    }

    private func discardPreviewDayPlan() {
        if let previewDayPlan {
            OnboardingDayPreviewFactory.discard(previewDayPlan, in: modelContext)
        }
        previewDayPlan = nil
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
