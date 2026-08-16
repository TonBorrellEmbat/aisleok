import Foundation
import SwiftUI

@MainActor
final class TriggerSettings: ObservableObject {
    @Published var enabled: [TriggerFamily: Bool] {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private let key = "aisleok.triggerFamilies"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.dictionary(forKey: key) as? [String: Bool] {
            var map: [TriggerFamily: Bool] = [:]
            for family in TriggerFamily.allCases {
                map[family] = stored[family.rawValue] ?? true
            }
            enabled = map
        } else {
            enabled = Dictionary(uniqueKeysWithValues: TriggerFamily.allCases.map { ($0, true) })
        }
    }

    func isOn(_ family: TriggerFamily) -> Bool {
        enabled[family] ?? true
    }

    func binding(for family: TriggerFamily) -> Binding<Bool> {
        Binding(
            get: { self.enabled[family] ?? true },
            set: { self.enabled[family] = $0 }
        )
    }

    var mutedTagIDs: Set<String> {
        var muted: Set<String> = []
        for tag in TriggerCatalog.tags {
            for family in TriggerFamily.allCases where !isOn(family) && family.contains(tag: tag) {
                muted.insert(tag.id)
            }
        }
        return muted
    }

    private func persist() {
        var stored: [String: Bool] = [:]
        for (family, value) in enabled {
            stored[family.rawValue] = value
        }
        defaults.set(stored, forKey: key)
    }
}
