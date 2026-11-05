import Foundation
import Observation
import PuzzliumCore
import PuzzliumDomain
import StoreKit

/// Category packs sold as non-consumable in-app purchases, plus one "all packs" purchase.
/// Ownership is read from StoreKit's entitlements (cached on device, so it works offline);
/// nothing is stored by the app.
@Observable
@MainActor
final class PackStore {
    nonisolated static let allPacksID = PackAccess.allPacksID
    nonisolated static let removeAdsID = PackAccess.removeAdsID

    nonisolated static func productID(for category: PuzzleCategory) -> String {
        PackAccess.productID(for: category)
    }

    private(set) var access = PackAccess()
    private(set) var products: [String: Product] = [:]
    private(set) var isPurchasing = false

    func product(for category: PuzzleCategory) -> Product? { products[Self.productID(for: category)] }
    var allPacks: Product? { products[Self.allPacksID] }
    var removeAds: Product? { products[Self.removeAdsID] }

    /// Loads ownership and prices, then follows transactions (Ask to Buy, refunds, other devices)
    /// for as long as the calling task lives.
    func run() async {
        await refreshEntitlements()
        let ids = PuzzleCategory.allCases.filter { $0 != .photos }.map(Self.productID) + [Self.allPacksID, Self.removeAdsID]
        do {
            products = Dictionary(uniqueKeysWithValues: try await Product.products(for: ids).map { ($0.id, $0) })
        } catch {
            Log.ui.error("Loading products failed: \(String(describing: error), privacy: .public)")
        }
        for await update in Transaction.updates {
            await refreshEntitlements()
            if case let .verified(transaction) = update {
                if transaction.revocationDate == nil { access.grant(transaction.productID) }
                await transaction.finish()
            }
        }
    }

    /// Cancelled and pending (Ask to Buy) purchases just return; approval arrives via `Transaction.updates`.
    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case let .success(.verified(transaction)):
                await transaction.finish()
                await refreshEntitlements()
                // currentEntitlements can lag right after a purchase, and in-app purchases never
                // come through Transaction.updates, so open what was just bought directly.
                access.grant(transaction.productID)
            case let .success(.unverified(transaction, error)):
                Log.ui.error("Purchase \(transaction.productID, privacy: .public) failed verification: \(String(describing: error), privacy: .public)")
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            Log.ui.error("Purchase failed: \(String(describing: error), privacy: .public)")
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            Log.ui.error("Restore failed: \(String(describing: error), privacy: .public)")
        }
        await refreshEntitlements()
    }

    /// Keeps a picture opened by a rewarded ad. Stored locally; reinstalling locks it again.
    func unlockWithAd(_ puzzleID: String) {
        access.adUnlocked.insert(puzzleID)
        UserDefaults.standard.set(Array(access.adUnlocked), forKey: Self.adUnlockedKey)
    }

    private static let adUnlockedKey = "adUnlockedPuzzles"

    private func refreshEntitlements() async {
        var access = PackAccess(adUnlocked: Set(UserDefaults.standard.stringArray(forKey: Self.adUnlockedKey) ?? []))
        for await result in Transaction.currentEntitlements {
            switch result {
            case let .verified(transaction) where transaction.revocationDate == nil:
                access.grant(transaction.productID)
            case let .unverified(transaction, error):
                Log.ui.error("Entitlement \(transaction.productID, privacy: .public) failed verification: \(String(describing: error), privacy: .public)")
            default:
                break
            }
        }
        self.access = access
    }
}
