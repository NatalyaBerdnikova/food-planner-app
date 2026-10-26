import StoreKit

@MainActor
enum StoreKitProductCatalog {
    private static var productsByID: [String: Product] = [:]

    /// Product IDs requested from StoreKit that were not returned.
    @discardableResult
    static func load(productIds: [String]) async -> [String] {
        let uniqueIds = Array(Set(productIds))
        let missing = Set(uniqueIds).subtracting(productsByID.keys)
        guard !missing.isEmpty else {
            return uniqueIds.filter { productsByID[$0] == nil }
        }

        do {
            let products = try await Product.products(for: Array(missing))
            for product in products {
                productsByID[product.id] = product
            }
            let unresolved = missing.subtracting(products.map(\.id))
            if !unresolved.isEmpty {
                print("StoreKitProductCatalog: StoreKit did not return: \(unresolved.sorted())")
            }
            return unresolved.sorted()
        } catch {
            print("StoreKitProductCatalog: failed to load products: \(error)")
            return missing.sorted()
        }
    }

    static func product(for productId: String) -> Product? {
        productsByID[productId]
    }
}
