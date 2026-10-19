import SwiftUI
import SwiftData
import UIKit

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onFinished: () -> Void

    @State private var step: Step = .welcome
    @State private var draft = OnboardingDraft()
    @State private var revealProgress = 0
    @State private var revealedNutrition: DailyNutrition?

    private enum Step: Int, CaseIterable {
        case welcome
        case goal
        case body
        case activity
        case reveal
    }

    private var isWelcome: Bool { step == .welcome }

    private var onPhotoChrome: Color { .white }
    private var onPhotoSecondary: Color { Color.white.opacity(0.88) }

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader
                if isWelcome {
                    welcomeLayout
                } else {
                    ScrollView {
                        stepContent
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(maxWidth: 560)
                            .frame(maxWidth: .infinity)
                    }
                    footer
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(isWelcome ? .dark : nil)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: step)
        .sensoryFeedback(.selection, trigger: step)
    }

    private var welcomeLayout: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)
            stepContent
                .padding(.horizontal, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            footer
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if isWelcome {
            welcomeBackground
        } else {
            AppTheme.canvas
        }
    }

    private var welcomeBackground: some View {
        ZStack {
            if UIImage(named: "OnboardingWelcome") != nil {
                Image("OnboardingWelcome")
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

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                if step != .welcome {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(Text("common.back"))
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
                Spacer()
                Text("onboarding.progress \(step.rawValue + 1) \(Step.allCases.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isWelcome ? onPhotoSecondary : Color.secondary)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }

            GeometryReader { geo in
                Capsule()
                    .fill(isWelcome ? onPhotoChrome.opacity(0.22) : Color.primary.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.accent)
                            .frame(width: geo.size.width * progressFraction)
                    }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)
            .accessibilityHidden(true)
        }
        .padding(.top, 8)
    }

    private var progressFraction: CGFloat {
        CGFloat(step.rawValue + 1) / CGFloat(Step.allCases.count)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            welcomeStep
        case .goal:
            choiceStep(
                title: "onboarding.goal.title",
                subtitle: "onboarding.goal.subtitle"
            ) {
                ForEach(NutritionGoal.allCases) { goal in
                    selectCard(
                        titleKey: goal.localizationKey,
                        selected: draft.goal == goal
                    ) {
                        draft.goal = goal
                    }
                }
            }
        case .body:
            bodyStep
        case .activity:
            choiceStep(
                title: "onboarding.activity.title",
                subtitle: "onboarding.activity.subtitle"
            ) {
                ForEach(ActivityLevel.allCases) { level in
                    selectCard(
                        titleKey: level.localizationKey,
                        selected: draft.activity == level
                    ) {
                        draft.activity = level
                    }
                }
            }
        case .reveal:
            revealStep
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("onboarding.welcome.title")
                .font(.largeTitle.bold())
                .foregroundStyle(onPhotoChrome)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 1)

            Text("onboarding.welcome.subtitle")
                .font(.title3)
                .foregroundStyle(onPhotoSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 14) {
                featureBullet(icon: "square.and.arrow.down.on.square", text: "onboarding.welcome.bullet.import")
                featureBullet(icon: "chart.bar.doc.horizontal", text: "onboarding.welcome.bullet.macros")
                featureBullet(icon: "leaf.circle", text: "onboarding.welcome.bullet.micros")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bodyStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepTitle("onboarding.body.title", subtitle: "onboarding.body.subtitle")

            Picker("onboarding.body.sex", selection: $draft.sex) {
                Text("calculator.sex.female").tag(BiologicalSex.female)
                Text("calculator.sex.male").tag(BiologicalSex.male)
            }
            .pickerStyle(.segmented)

            stepperRow(title: "onboarding.body.age", value: "\(draft.age)") {
                Stepper("", value: $draft.age, in: 14...80)
                    .labelsHidden()
            }

            sliderRow(
                title: "onboarding.body.height",
                valueText: "\(Int(draft.heightCm)) cm",
                value: $draft.heightCm,
                range: 140...210,
                step: 1
            )
            sliderRow(
                title: "onboarding.body.weight",
                valueText: String(format: "%.1f kg", draft.weightKg),
                value: $draft.weightKg,
                range: 40...180,
                step: 0.5
            )
            sliderRow(
                title: "onboarding.body.targetWeight",
                valueText: String(format: "%.1f kg", draft.targetWeightKg),
                value: $draft.targetWeightKg,
                range: 40...180,
                step: 0.5
            )
        }
    }

    private var revealStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepTitle("onboarding.reveal.title", subtitle: "onboarding.reveal.subtitle")

            if revealProgress < 3 {
                VStack(spacing: 16) {
                    SparklesLoader(tint: AppTheme.accent)
                    Text(revealStatusKey)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .accessibilityElement(children: .combine)
            } else if let nutrition = revealedNutrition {
                VStack(spacing: 14) {
                    macroRevealRow(title: "nutrition.macro.kcal.full", value: nutrition.calories, unit: "kcal")
                    macroRevealRow(title: "nutrition.macro.protein.full", value: nutrition.protein, unit: "g")
                    macroRevealRow(title: "nutrition.macro.fat.full", value: nutrition.fat, unit: "g")
                    macroRevealRow(title: "nutrition.macro.carbs.full", value: nutrition.carbs, unit: "g")
                }

                Text("onboarding.reveal.disclaimer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .task(id: step) {
            guard step == .reveal else { return }
            await runReveal()
        }
    }

    private var revealStatusKey: LocalizedStringKey {
        switch revealProgress {
        case 0: "onboarding.reveal.status.macros"
        case 1: "onboarding.reveal.status.micros"
        default: "onboarding.reveal.status.plan"
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: advance) {
                Text(primaryButtonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppTheme.controlMinHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.55)

            if step == .welcome {
                Button("onboarding.cta.defaults") {
                    applyDefaultsAndReveal()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(onPhotoSecondary)
                .frame(minHeight: 44)
            }
        }
    }

    private var primaryButtonTitle: LocalizedStringKey {
        switch step {
        case .welcome: "onboarding.cta.start"
        case .reveal: "onboarding.cta.unlock"
        default: "onboarding.cta.continue"
        }
    }

    private var canAdvance: Bool {
        if case .reveal = step {
            return revealProgress >= 3 && revealedNutrition != nil
        }
        return true
    }

    private func advance() {
        if step == .reveal {
            finishOnboarding()
            return
        }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    private func applyDefaultsAndReveal() {
        draft = OnboardingDraft()
        draft.micronutrientFocus = [.fiber, .vitaminD3, .iron]
        step = .reveal
    }

    private func finishOnboarding() {
        if draft.micronutrientFocus.isEmpty {
            draft.micronutrientFocus = [.fiber, .vitaminD3, .iron]
        }
        guard let nutrition = revealedNutrition ?? draft.calculatedNutrition() else { return }
        let settings = AppSettingsService.settings(in: modelContext)
        settings.apply(onboarding: draft, nutrition: nutrition)
        LocalPersistence.save(modelContext)
        onFinished()
    }

    private func runReveal() async {
        revealProgress = 0
        revealedNutrition = nil
        let delay: Duration = reduceMotion ? .milliseconds(120) : .milliseconds(550)
        for tick in 0..<3 {
            try? await Task.sleep(for: delay)
            revealProgress = tick + 1
        }
        revealedNutrition = draft.calculatedNutrition()
            ?? DailyNutrition(calories: 2000, protein: 90, fat: 70, carbs: 250)
    }

    private func choiceStep<Content: View>(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(title, subtitle: subtitle)
            content()
        }
    }

    private func stepTitle(_ title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func selectCard(
        titleKey: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(LocalizedStringKey(titleKey))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppTheme.accent : Color.secondary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(minHeight: AppTheme.controlMinHeight)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? AppTheme.accentSoft : AppTheme.elevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        selected ? AppTheme.accent.opacity(0.55) : Color.primary.opacity(0.08),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func featureBullet(icon: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(onPhotoChrome)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stepperRow(title: LocalizedStringKey, value: String, @ViewBuilder control: () -> some View) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            control()
                .tint(AppTheme.accent)
        }
        .padding(16)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sliderRow(
        title: LocalizedStringKey,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Text(valueText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
                .tint(AppTheme.accent)
        }
        .padding(16)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func macroRevealRow(title: LocalizedStringKey, value: Double, unit: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(value.rounded())) \(unit)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
