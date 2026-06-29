import Foundation
import SwiftData

@MainActor
final class SubscriptionSession: ObservableObject {
    @Published var isPro = false
    @Published var isFree = false
    @Published var loaderPresented = false
    @Published var alertPresented = false
    @Published var alertText = ""
    @Published var paymentPresented = false

    var hasFullAccess: Bool { isPro || isFree }

    func load(from settings: AppSettings) {
        isPro = settings.isPro
        isFree = settings.isFree
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
