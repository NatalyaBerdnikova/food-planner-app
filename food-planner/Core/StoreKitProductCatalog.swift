import StoreKit

@MainActor
enum StoreKitProductCatalog {
    private static var productsByID: [String: Product] = [:]

    static func load(productIds: [String]) async {
        let missing = Set(productIds).subtracting(productsByID.keys)
        guard !missing.isEmpty else { return }

        do {
            let products = try await Product.products(for: Array(missing))
            for product in products {
                productsByID[product.id] = product
            }
        } catch {
            print("StoreKitProductCatalog: failed to load products: \(error)")
        }
    }

    static func product(for productId: String) -> Product? {
        productsByID[productId]
    }
}
