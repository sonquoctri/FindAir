import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    static let shared = SubscriptionStore()
    static let weeklyProductID = "com.sqt.FindAir.Weekly"
    static let lifetimeProductID = "com.sqt.FindAir.LifeTime"

    @Published private(set) var weeklyProduct: Product?
    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var hasWeeklyAccess = false
    @Published private(set) var hasLifetimeAccess = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            await self?.refreshEntitlements()
            await self?.observeTransactionUpdates()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProduct() async {
        guard (weeklyProduct == nil || lifetimeProduct == nil), !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [Self.weeklyProductID, Self.lifetimeProductID])
            weeklyProduct = products.first { $0.id == Self.weeklyProductID }
            lifetimeProduct = products.first { $0.id == Self.lifetimeProductID }

            if weeklyProduct == nil && lifetimeProduct == nil {
                errorMessage = "Subscription products are currently unavailable."
            }
        } catch {
            errorMessage = "Unable to load the subscription. Please try again."
        }
    }

    func purchase() async -> Bool {
        guard let weeklyProduct else {
            await loadProduct()
            guard let weeklyProduct else {
                return false
            }
            return await purchase(weeklyProduct)
        }

        return await purchase(weeklyProduct)
    }

    func purchaseLifetime() async -> Bool {
        guard let lifetimeProduct else {
            await loadProduct()
            guard let lifetimeProduct else {
                return false
            }
            return await purchase(lifetimeProduct)
        }

        return await purchase(lifetimeProduct)
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "Unable to restore purchases. Please try again."
        }
    }

    var hasPremiumAccess: Bool {
        hasWeeklyAccess || hasLifetimeAccess
    }

    func refreshEntitlements() async {
        var weeklyAccess = false
        var lifetimeAccess = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            switch transaction.productID {
            case Self.weeklyProductID:
                weeklyAccess = true
            case Self.lifetimeProductID:
                lifetimeAccess = true
            default:
                break
            }
        }

        hasWeeklyAccess = weeklyAccess
        hasLifetimeAccess = lifetimeAccess
    }

    private func purchase(_ product: Product) async -> Bool {
        guard !isPurchasing else {
            return false
        }

        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "The purchase could not be completed. Please try again."
            return false
        }
    }

    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            do {
                let transaction = try checkVerified(update)
                await transaction.finish()
                await refreshEntitlements()
            } catch {
                errorMessage = "We could not verify the subscription purchase."
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw SubscriptionError.unverifiedTransaction
        }
    }
}

private enum SubscriptionError: Error {
    case unverifiedTransaction
}
