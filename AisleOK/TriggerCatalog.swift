import Foundation

struct TriggerTag: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let displayName: String
    let aliases: [String]
    let defaultBand: Band
    let ifLate: Band
    let category: String
    let kind: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case aliases
        case defaultBand = "default_band"
        case ifLate = "if_late"
        case category, kind
    }
}

struct TriggerFile: Codable {
    let tags: [TriggerTag]
    let scoring: ScoringMeta?
    let nonTags: [String]?

    struct ScoringMeta: Codable {
        let exactTokenOnlyIds: [String]?
        enum CodingKeys: String, CodingKey {
            case exactTokenOnlyIds = "exact_token_only_ids"
        }
    }

    enum CodingKeys: String, CodingKey {
        case tags, scoring
        case nonTags = "non_tags"
    }
}

enum TriggerFamily: String, CaseIterable, Identifiable {
    case onion, garlic, wheat, lactose, polyols, inulin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onion: return "Onion"
        case .garlic: return "Garlic"
        case .wheat: return "Wheat"
        case .lactose: return "Lactose"
        case .polyols: return "Polyols"
        case .inulin: return "Inulin"
        }
    }

    func contains(tag: TriggerTag) -> Bool {
        switch self {
        case .onion:
            return ["onion", "onion_powder", "onion_salt", "shallot", "leek", "scallion", "chives"].contains(tag.id)
        case .garlic:
            return tag.id.hasPrefix("garlic")
        case .wheat:
            return ["wheat", "durum", "couscous", "spelt", "farro", "rye", "barley"].contains(tag.id)
        case .lactose:
            return tag.category == "lactose"
        case .polyols:
            return tag.category == "polyol"
        case .inulin:
            return tag.id == "inulin" || tag.id == "jerusalem_artichoke"
        }
    }
}

enum TriggerCatalog {
    static let exactTokenOnly: Set<String> = [
        "milk", "cream", "whey", "yogurt", "lactose", "buttermilk", "ice_cream", "soft_cheese"
    ]

    static let tags: [TriggerTag] = loadTags()

    static func load(from url: URL) throws -> [TriggerTag] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(TriggerFile.self, from: data).tags
    }

    static func locateJSON(in bundles: [Bundle] = Bundle.allBundles + Bundle.allFrameworks) -> URL? {
        for bundle in bundles {
            if let url = bundle.url(forResource: "AisleOK_trigger_tags_v1", withExtension: "json") {
                return url
            }
        }
        return nil
    }

    private static func loadTags() -> [TriggerTag] {
        if let url = locateJSON() {
            return (try? load(from: url)) ?? []
        }
        return []
    }
}
