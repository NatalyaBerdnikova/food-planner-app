import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum AppAnalytics {
    private static let configuredKey = "analytics.firebaseConfigured"
    private static let activatedKey = "analytics.activated"
    private static let tutorialBeginSeenKey = "analytics.tutorialBeginSeen"
    private static let trialStartDateKey = "analytics.trialStartDate"
    private static let maxStringLength = 100

    private(set) static var isEnabled = false

    static var isActivated: Bool {
        UserDefaults.standard.bool(forKey: activatedKey)
    }

    static func configureIfPossible() {
        guard !isEnabled else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        isEnabled = true
        UserDefaults.standard.set(true, forKey: configuredKey)
        syncPersistedUserProperties()
        #endif
    }

    static func log(_ name: String, _ parameters: [String: Any] = [:]) {
        guard isEnabled else { return }
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: sanitize(parameters))
        #endif
    }

    static func setUserProperty(_ name: String, value: String?) {
        guard isEnabled else { return }
        #if canImport(FirebaseAnalytics)
        let trimmed = value.map { truncate($0) }
        Analytics.setUserProperty(trimmed, forName: name)
        #endif
    }

    static func syncPersistedUserProperties() {
        setUserProperty("activated", value: isActivated ? "true" : "false")
        let language = resolvedAppLanguageCode()
        setUserProperty("app_language", value: language)
    }

    static func setSubscriptionStatus(_ status: String, planID: String) {
        setUserProperty("subscription_status", value: status)
        setUserProperty("plan_id", value: planID)
    }

    static func setGoalType(_ goalType: String) {
        setUserProperty("goal_type", value: goalType)
    }

    static func setOnboardingCompleted(_ completed: Bool) {
        setUserProperty("onboarding_completed", value: completed ? "true" : "false")
    }

    static func setAppLanguage(_ code: String) {
        setUserProperty("app_language", value: code)
    }

    static func markActivatedIfNeeded(activationType: String) {
        guard !isActivated else { return }
        UserDefaults.standard.set(true, forKey: activatedKey)
        setUserProperty("activated", value: "true")
        var params: [String: Any] = ["activation_type": activationType]
        if let trialStart = UserDefaults.standard.object(forKey: trialStartDateKey) as? Date {
            params["hours_since_trial_start"] = Int(Date().timeIntervalSince(trialStart) / 3600)
        }
        log("user_activated", params)
    }

    static func rememberTrialStart() {
        if UserDefaults.standard.object(forKey: trialStartDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: trialStartDateKey)
        }
    }

    static func tutorialBeginSource() -> String {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: tutorialBeginSeenKey) {
            return "reinstall"
        }
        defaults.set(true, forKey: tutorialBeginSeenKey)
        return "first_open"
    }

    static func analyticsPlanID(forVendorProductID vendorID: String) -> String {
        let lowered = vendorID.lowercased()
        if lowered.contains("lifetime") || lowered.contains("life_time") {
            return "lifetime"
        }
        if lowered.contains("year") || lowered.contains("annual") {
            return "yearly"
        }
        if lowered.contains("month") {
            return "monthly"
        }
        return truncate(vendorID)
    }

    static func analyticsPlanID(kindRaw: String) -> String {
        switch kindRaw {
        case "lifetime": return "lifetime"
        case "annual", "yearly": return "yearly"
        case "monthly": return "monthly"
        default: return analyticsPlanID(forVendorProductID: kindRaw)
        }
    }

    static func isUserCancelledPurchaseError(_ message: String) -> Bool {
        let lowered = message.lowercased()
        return lowered.contains("cancel")
            || lowered.contains("отмен")
            || lowered.contains("user cancelled")
            || lowered.contains("payment cancelled")
    }

    private static func sanitize(_ parameters: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in parameters {
            let safeKey = String(key.prefix(40))
            switch value {
            case let string as String:
                result[safeKey] = truncate(string)
            case let bool as Bool:
                result[safeKey] = bool
            case let int as Int:
                result[safeKey] = int
            case let double as Double:
                result[safeKey] = double
            case let number as NSNumber:
                result[safeKey] = number
            default:
                result[safeKey] = truncate(String(describing: value))
            }
        }
        return result
    }

    private static func truncate(_ value: String) -> String {
        String(value.prefix(maxStringLength))
    }

    private static func resolvedAppLanguageCode() -> String {
        let raw = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.system.rawValue
        switch AppLanguage(rawValue: raw) ?? .system {
        case .english: return "en"
        case .russian: return "ru"
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
    }
}

extension AppAnalytics {
    static func logTutorialBegin() {
        log("tutorial_begin", ["source": tutorialBeginSource()])
    }

    static func logOnboardingStepView(stepName: String, stepIndex: Int) {
        log("onboarding_step_view", [
            "step_name": stepName,
            "step_index": stepIndex,
        ])
    }

    static func logOnboardingStepComplete(stepName: String, stepIndex: Int) {
        log("onboarding_step_complete", [
            "step_name": stepName,
            "step_index": stepIndex,
        ])
    }

    static func logOnboardingGoalSet(goalType: String) {
        log("onboarding_goal_set", ["goal_type": goalType])
        setGoalType(goalType)
    }

    static func logOnboardingTargetsReady(calories: Int, proteinG: Int, fatG: Int, carbsG: Int) {
        log("onboarding_targets_ready", [
            "calories": calories,
            "protein_g": proteinG,
            "fat_g": fatG,
            "carbs_g": carbsG,
        ])
    }

    static func logTutorialComplete(stepsCompleted: Int) {
        log("tutorial_complete", ["steps_completed": stepsCompleted])
        setOnboardingCompleted(true)
    }

    static func logPlanPreviewView(calories: Int, mealsCount: Int) {
        log("plan_preview_view", [
            "calories": calories,
            "meals_count": mealsCount,
        ])
    }

    static func logPaywallView(trigger: String, defaultPlan: String) {
        log("paywall_view", [
            "trigger": trigger,
            "default_plan": defaultPlan,
        ])
    }

    static func logPaywallPlanSelect(planID: String, hasTrial: Bool) {
        log("paywall_plan_select", [
            "plan_id": planID,
            "has_trial": hasTrial,
        ])
    }

    static func logPaywallCTATap(planID: String, ctaText: String) {
        log("paywall_cta_tap", [
            "plan_id": planID,
            "cta_text": ctaText,
        ])
    }

    static func logPaywallRestoreTap() {
        log("paywall_restore_tap")
    }

    static func logPaywallLinkTap(linkType: String) {
        log("paywall_link_tap", ["link_type": linkType])
    }

    static func logBeginCheckout(itemID: String, value: Double?, currency: String?) {
        var params: [String: Any] = ["item_id": itemID]
        if let value { params["value"] = value }
        if let currency { params["currency"] = currency }
        log("begin_checkout", params)
    }

    static func logPurchase(itemID: String, value: Double?, currency: String?, transactionID: String?) {
        var params: [String: Any] = ["item_id": itemID]
        if let value { params["value"] = value }
        if let currency { params["currency"] = currency }
        if let transactionID { params["transaction_id"] = transactionID }
        log("purchase", params)
    }

    static func logTrialStart(planID: String, trialDays: Int = 14) {
        rememberTrialStart()
        log("trial_start", [
            "plan_id": planID,
            "trial_days": trialDays,
        ])
        setSubscriptionStatus("trial", planID: planID)
    }

    static func logPurchaseError(planID: String, errorCode: String, isUserCancelled: Bool) {
        log("purchase_error", [
            "plan_id": planID,
            "error_code": errorCode,
            "is_user_cancelled": isUserCancelled,
        ])
    }

    static func logRestoreResult(success: Bool, hasActiveEntitlement: Bool) {
        log("restore_result", [
            "success": success,
            "has_active_entitlement": hasActiveEntitlement,
        ])
    }

    static func logPlanWeekView(source: String) {
        log("plan_week_view", ["source": source])
    }

    static func logPlanEdit(editType: String) {
        log("plan_edit", ["edit_type": editType])
        markActivatedIfNeeded(activationType: "plan_edit")
    }

    static func logPlanGenerateStart(replaceExisting: Bool) {
        log("plan_generate_start", ["replace_existing": replaceExisting])
    }

    static func logPlanGenerateSuccess(mealsCount: Int, daysFilled: Int) {
        log("plan_generate_success", [
            "meals_count": mealsCount,
            "days_filled": daysFilled,
        ])
        markActivatedIfNeeded(activationType: "plan_generate_success")
    }

    static func logPlanGenerateError(errorCode: String, stage: String) {
        log("plan_generate_error", [
            "error_code": errorCode,
            "stage": stage,
        ])
    }

    static func logPlanExportStart(mealsCount: Int, filledDays: Int) {
        log("plan_export_start", [
            "meals_count": mealsCount,
            "filled_days": filledDays,
        ])
    }

    static func logPlanExportShare(hasCustomFilename: Bool) {
        log("plan_export_share", ["has_custom_filename": hasCustomFilename])
        log("share", ["content_type": "foodplan"])
    }

    static func logPlanImportPreview(mode: String) {
        log("plan_import_preview", ["mode": mode])
    }

    static func logPlanImportApply(mode: String, targetWeekOffset: Int) {
        log("plan_import_apply", [
            "mode": mode,
            "target_week_offset": targetWeekOffset,
        ])
        markActivatedIfNeeded(activationType: "plan_import_apply")
    }

    static func logShoppingListOpen(itemsCount: Int) {
        log("shopping_list_open", ["items_count": itemsCount])
        markActivatedIfNeeded(activationType: "shopping_list_open")
    }

    static func logInstagramImportStart(source: String) {
        log("instagram_import_start", ["source": source])
    }

    static func logInstagramImportSuccess(itemsCount: Int) {
        log("instagram_import_success", ["items_count": itemsCount])
        markActivatedIfNeeded(activationType: "instagram_import_success")
    }

    static func logInstagramImportError(errorCode: String) {
        log("instagram_import_error", ["error_code": errorCode])
    }

    static func logRecipeFavorite(catalogRecipeID: String, on: Bool) {
        log("recipe_favorite", [
            "catalog_recipe_id": catalogRecipeID,
            "on": on,
        ])
    }

    static func logRecipeRate(rating: Int) {
        log("recipe_rate", ["rating": rating])
    }

    static func logMicronutrientLimitHit() {
        log("micronutrient_limit_hit")
    }

    static func logTrialReminderScheduled(day: Int) {
        log("trial_reminder_scheduled", ["day": day])
    }

    static func logNotificationOpen(campaignID: String, day: Int) {
        log("notification_open", [
            "campaign_id": campaignID,
            "day": day,
        ])
    }

    static func logRatePromptView(trigger: String) {
        log("rate_prompt_view", ["trigger": trigger])
    }
}
