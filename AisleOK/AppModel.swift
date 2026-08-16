import Foundation
import SwiftUI

enum Route: Hashable {
    case verdict(UUID)
    case settings
    case produceSearch
    case labelOCR
}

enum ScanSource: String, Hashable {
    case barcode, ocr, produce
}

struct ScanOutcome: Identifiable, Hashable {
    let id: UUID
    var productName: String
    var score: ScoreResult
    var offCode: String?
    var offURL: URL?
    var source: ScanSource
    var looksWrongApplied: Bool

    var isUnknown: Bool { score.band == .unknown }

    mutating func applyLooksWrong() {
        looksWrongApplied = true
        score = .unknown()
        // Keep the product name. Drop the ingredient list by not storing it.
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var path: [Route] = []
    @Published var outcomes: [UUID: ScanOutcome] = [:]
    @Published var showPaywall = false
    @Published var showOnboarding: Bool
    @Published var isWorking = false
    @Published var scanMessage: String?
    @Published var lastOutcome: ScanOutcome?

    let settings: TriggerSettings
    let store: StoreKitStore

    private let defaults: UserDefaults
    private let freeScanKey = "aisleok.hasCompletedFreeScan"
    private let onboardingKey = "aisleok.hasCompletedOnboarding"

    @Published var hasCompletedFreeScan: Bool {
        didSet { defaults.set(hasCompletedFreeScan, forKey: freeScanKey) }
    }

    init(settings: TriggerSettings, store: StoreKitStore, defaults: UserDefaults = .standard) {
        self.settings = settings
        self.store = store
        self.defaults = defaults
        self.hasCompletedFreeScan = defaults.bool(forKey: freeScanKey)
        self.showOnboarding = !defaults.bool(forKey: onboardingKey)
    }

    var matcher: TriggerMatcher {
        TriggerMatcher(tags: TriggerCatalog.tags, mutedTagIDs: settings.mutedTagIDs)
    }

    var canScanFreely: Bool {
        store.isEntitled || !hasCompletedFreeScan
    }

    func finishOnboarding() {
        defaults.set(true, forKey: onboardingKey)
        showOnboarding = false
    }

    func requestAccessForNewScan() -> Bool {
        if canScanFreely { return true }
        showPaywall = true
        return false
    }

    func popToRoot() {
        path.removeAll()
    }

    func openSettings() {
        path.append(.settings)
    }

    func openProduceSearch() {
        guard requestAccessForNewScan() else { return }
        path.append(.produceSearch)
    }

    func openLabelOCR() {
        guard requestAccessForNewScan() else { return }
        path.append(.labelOCR)
    }

    func present(_ outcome: ScanOutcome, markUseful: Bool) {
        outcomes[outcome.id] = outcome
        lastOutcome = outcome
        path.append(.verdict(outcome.id))
        if markUseful {
            recordUsefulScan()
        }
    }

    func recordUsefulScan() {
        if !store.isEntitled {
            let first = !hasCompletedFreeScan
            hasCompletedFreeScan = true
            if first {
                showPaywall = true
            }
        }
    }

    func update(_ outcome: ScanOutcome) {
        outcomes[outcome.id] = outcome
    }

    func handleBarcode(_ code: String) {
        guard requestAccessForNewScan() else { return }
        Task { await lookupBarcode(code) }
    }

    func lookupBarcode(_ code: String) async {
        guard !isWorking else { return }
        isWorking = true
        scanMessage = nil
        defer { isWorking = false }
        do {
            let product = try await OpenFoodFactsClient.fetch(code: code)
            if let product {
                let score: ScoreResult
                if product.hasIngredients {
                    score = matcher.scoreIngredients(product.ingredients)
                } else {
                    score = .unknown()
                }
                let outcome = ScanOutcome(
                    id: UUID(),
                    productName: product.name,
                    score: score,
                    offCode: product.code,
                    offURL: product.pageURL,
                    source: .barcode,
                    looksWrongApplied: false
                )
                present(outcome, markUseful: true)
            } else {
                let outcome = ScanOutcome(
                    id: UUID(),
                    productName: "Scanned item",
                    score: .unknown(),
                    offCode: OpenFoodFactsClient.normalizedCode(code),
                    offURL: OpenFoodFactsClient.pageURL(code: code),
                    source: .barcode,
                    looksWrongApplied: false
                )
                present(outcome, markUseful: true)
            }
        } catch {
            scanMessage = "Couldn’t reach Open Food Facts."
            let outcome = ScanOutcome(
                id: UUID(),
                productName: "Scanned item",
                score: .unknown(),
                offCode: OpenFoodFactsClient.normalizedCode(code),
                offURL: OpenFoodFactsClient.pageURL(code: code),
                source: .barcode,
                looksWrongApplied: false
            )
            present(outcome, markUseful: true)
        }
    }

    func handleProduce(_ query: String) -> ScanOutcome {
        let score = matcher.scoreName(query)
        return ScanOutcome(
            id: UUID(),
            productName: query.trimmingCharacters(in: .whitespacesAndNewlines),
            score: score,
            offCode: nil,
            offURL: nil,
            source: .produce,
            looksWrongApplied: false
        )
    }

    func handleOCR(text: String, fallbackName: String) {
        let ingredients = Self.ingredients(fromOCR: text)
        let score = matcher.scoreIngredients(ingredients)
        let name = Self.productName(fromOCR: text) ?? fallbackName
        let outcome = ScanOutcome(
            id: UUID(),
            productName: name,
            score: score,
            offCode: nil,
            offURL: nil,
            source: .ocr,
            looksWrongApplied: false
        )
        present(outcome, markUseful: true)
    }

    static func ingredients(fromOCR text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: "ingredients", options: .caseInsensitive) {
            return String(trimmed[range.lowerBound...])
        }
        return trimmed
    }

    static func productName(fromOCR text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let first = lines.first else { return nil }
        if first.lowercased().contains("ingredient") { return nil }
        if first.count > 48 { return nil }
        return first
    }
}
