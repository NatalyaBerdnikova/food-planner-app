import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SubscriptionSession {
    var isPro = false
    var isFree = false
    var isAccessResolved = false
    var loaderPresented = false
    var alertPresented = false
    var alertText = ""
    var paymentPresented = false

    var hasFullAccess: Bool { isPro || isFree }

    func load(from settings: AppSettings) {
        isPro = settings.isPro
        isFree = settings.isFree
    }

    func applyAccessCheck(_ result: PurchaseService.AccessCheckResult) {
        switch result {
        case .active:
            isPro = true
        case .inactive:
            isPro = false
        case .unknown:
            break
        }
        isAccessResolved = true
    }

    func persist(to settings: AppSettings, in context: ModelContext) {
        settings.isPro = isPro
        settings.isFree = isFree
        LocalPersistence.save(context)
    }

    func upgradeToPro(settings: AppSettings, in context: ModelContext) {
        isPro = true
        persist(to: settings, in: context)
    }

    func upgradeToFree(settings: AppSettings, in context: ModelContext) {
        isFree = true
        persist(to: settings, in: context)
    }

    func showLoader() {
        loaderPresented = true
    }

    func hideLoader() {
        loaderPresented = false
    }

    func showAlert(_ text: String) {
        alertText = text
        alertPresented = true
    }

    func showPayment() {
        paymentPresented = true
    }
}
