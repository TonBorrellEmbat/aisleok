import Foundation
import StoreKit

@MainActor
final class StoreKitStore: ObservableObject {
    @Published private(set) var isEntitled = false
    @Published private(set) var products: [Product] = []
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func refresh() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Set(StoreProductID.all))
                .sorted { lhs, rhs in
                    if lhs.id == StoreProductID.yearly { return true }
                    if rhs.id == StoreProductID.yearly { return false }
                    return lhs.id < rhs.id
                }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? check(result),
               StoreProductID.all.contains(transaction.productID) {
                entitled = true
                break
            }
        }
        isEntitled = entitled
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try check(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchaseYearly() async {
        if let product = products.first(where: { $0.id == StoreProductID.yearly }) {
            await purchase(product)
        } else {
            lastError = "Yearly product is unavailable."
        }
    }

    func purchaseMonthly() async {
        if let product = products.first(where: { $0.id == StoreProductID.monthly }) {
            await purchase(product)
        } else {
            lastError = "Monthly product is unavailable."
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? check(result) {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    private func check<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
