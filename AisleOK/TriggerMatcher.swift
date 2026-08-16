import Foundation

struct ScoreResult: Equatable, Hashable {
    var band: Band
    var displayName: String?
    var tagId: String?
    var category: String?
    var detail: String
    var doseLine: String?

    static func unknown(detail: String = "We don’t know this one.") -> ScoreResult {
        ScoreResult(band: .unknown, displayName: nil, tagId: nil, category: nil, detail: detail, doseLine: nil)
    }

    static func eat(detail: String = "No IBS triggers in this one.") -> ScoreResult {
        ScoreResult(band: .eat, displayName: nil, tagId: nil, category: nil, detail: detail, doseLine: nil)
    }
}

struct TriggerMatcher {
    let tags: [TriggerTag]
    let exactTokenOnly: Set<String>
    let mutedTagIDs: Set<String>

    init(
        tags: [TriggerTag],
        exactTokenOnly: Set<String> = TriggerCatalog.exactTokenOnly,
        mutedTagIDs: Set<String> = []
    ) {
        self.tags = tags
        self.exactTokenOnly = exactTokenOnly
        self.mutedTagIDs = mutedTagIDs
    }

    static func normalize(_ raw: String) -> String {
        let lowered = raw.lowercased()
        var chars: [Character] = []
        chars.reserveCapacity(lowered.count)
        for ch in lowered {
            if ch.isLetter || ch.isNumber || ch == "-" || ch == " " {
                chars.append(ch)
            } else {
                chars.append(" ")
            }
        }
        return String(chars).split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    static func peelParens(_ raw: String) -> (outer: String, inners: [String]) {
        var outer = ""
        var inners: [String] = []
        var currentInner = ""
        var depth = 0
        for ch in raw {
            if ch == "(" {
                depth += 1
                if depth == 1 {
                    currentInner = ""
                    continue
                }
            }
            if ch == ")" {
                if depth == 1 {
                    inners.append(currentInner)
                    depth = 0
                    continue
                }
                if depth > 0 { depth -= 1 }
            }
            if depth == 0 {
                outer.append(ch)
            } else {
                currentInner.append(ch)
            }
        }
        return (outer, inners)
    }

    /// Comma-split tokens with 0-based source index. Parentheticals share the outer index.
    static func positionedTokens(from ingredients: String) -> [(token: String, index: Int)] {
        var text = ingredients
        if let range = text.range(of: #"^\s*ingredients\s*:"#, options: [.regularExpression, .caseInsensitive]) {
            text.removeSubrange(range)
        }
        var result: [(String, Int)] = []
        let parts = text.split(whereSeparator: { $0 == "," || $0 == ";" })
        for (idx, part) in parts.enumerated() {
            let peeled = peelParens(String(part))
            let outer = normalize(peeled.outer)
            let outerWords = Set(outer.split(separator: " ").map(String.init))
            let carrier = !outerWords.isDisjoint(with: ["oil", "oils", "starch", "syrup"])
            if !outer.isEmpty {
                result.append((outer, idx))
            }
            // soybean oil / vegetable oils (rapeseed and soybean) are not soybeans
            if !carrier {
                for inner in peeled.inners {
                    let n = normalize(inner)
                    if !n.isEmpty {
                        result.append((n, idx))
                    }
                }
            }
        }
        return result
    }

    private static func simplePluralVariants(_ alias: String) -> Set<String> {
        var set: Set<String> = [alias]
        if alias.hasSuffix("ies"), alias.count > 3 {
            set.insert(String(alias.dropLast(3)) + "y")
        } else if alias.hasSuffix("es"), alias.count > 2 {
            set.insert(String(alias.dropLast(2)))
            set.insert(String(alias.dropLast(1)))
        } else if alias.hasSuffix("s"), !alias.hasSuffix("ss"), alias.count > 1 {
            set.insert(String(alias.dropLast()))
        } else {
            set.insert(alias + "s")
            set.insert(alias + "es")
            if alias.hasSuffix("y"), alias.count > 1 {
                set.insert(String(alias.dropLast()) + "ies")
            }
        }
        return set
    }

    private struct AliasHit {
        let tag: TriggerTag
        let alias: String
    }

    private func aliasIndex() -> [AliasHit] {
        var hits: [AliasHit] = []
        for tag in tags where !mutedTagIDs.contains(tag.id) {
            for alias in tag.aliases {
                let n = Self.normalize(alias)
                for v in Self.simplePluralVariants(n) {
                    hits.append(AliasHit(tag: tag, alias: v))
                }
            }
        }
        return hits.sorted { $0.alias.count > $1.alias.count }
    }

    private static let nonTags: Set<String> = [
        "natural flavor", "natural flavors", "spices", "spice", "yeast extract"
    ]

    private func match(token: String, hits: [AliasHit]) -> TriggerTag? {
        guard !token.isEmpty else { return nil }
        if Self.nonTags.contains(token) { return nil }

        // Longest alias first, whole token (or simple plural/singular).
        for hit in hits {
            if token == hit.alias { return hit.tag }
        }

        // Head-noun: last word may match, except lactose-family (exact-token only).
        let words = token.split(separator: " ").map(String.init)
        if words.contains(where: { ["oil", "oils", "starch", "syrup"].contains($0) }) {
            return nil
        }
        let last = words.last ?? token
        for hit in hits {
            if exactTokenOnly.contains(hit.tag.id) { continue }
            if last == hit.alias { return hit.tag }
        }
        return nil
    }

    private func result(for tag: TriggerTag, band: Band) -> ScoreResult {
        let dose: String?
        if band == .small {
            dose = "A few spoons. Not the cup."
        } else {
            dose = nil
        }
        let detail: String
        switch band {
        case .small, .skip:
            detail = tag.displayName
        case .eat:
            detail = "No IBS triggers in this one."
        case .unknown:
            detail = "We don’t know this one."
        }
        return ScoreResult(
            band: band,
            displayName: tag.displayName,
            tagId: tag.id,
            category: tag.category,
            detail: detail,
            doseLine: dose
        )
    }

    /// Packaged label (barcode / OCR): first 5 use default_band; after 5 use if_late.
    /// Non-empty list with zero trusted skip/small matches → Eat (soybean oil alone).
    func scoreIngredients(_ ingredients: String?) -> ScoreResult {
        guard let ingredients, !ingredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .unknown()
        }
        let toks = Self.positionedTokens(from: ingredients)
        guard !toks.isEmpty else { return .unknown() }
        let hits = aliasIndex()
        var best: (band: Band, tag: TriggerTag, index: Int)?
        for item in toks {
            guard let tag = match(token: item.token, hits: hits) else { continue }
            let band = item.index < 5 ? tag.defaultBand : tag.ifLate
            if band == .unknown { continue }
            if let current = best {
                if band > current.band || (band == current.band && item.index < current.index) {
                    best = (band, tag, item.index)
                }
            } else {
                best = (band, tag, item.index)
            }
        }
        if let best {
            return result(for: best.tag, band: best.band)
        }
        return .eat()
    }

    /// Typed produce / name search: default_band only. No match → Unknown.
    func scoreName(_ name: String) -> ScoreResult {
        let token = Self.normalize(name)
        guard !token.isEmpty else { return .unknown() }
        let hits = aliasIndex()
        if let tag = match(token: token, hits: hits) {
            return result(for: tag, band: tag.defaultBand)
        }
        return .unknown()
    }
}

enum WhyCopy {
    static func lines(for tag: TriggerTag) -> (what: String, why: String, small: String) {
        switch tag.category {
        case "lactose":
            return (
                "\(tag.displayName.capitalized) is a milk sugar some people notice.",
                "A cup of yogurt or a glass of milk is a lot of it at once.",
                "A few spoons is the usual small serve. Not the whole cup."
            )
        case "polyol":
            return (
                "\(tag.displayName.capitalized) is a sugar alcohol or a fruit that carries one.",
                "Some people with a sensitive gut notice these even in a modest serve.",
                "Small means a taste or a few slices, not a bowl."
            )
        case "fructan" where tag.id.hasPrefix("garlic") || tag.id.contains("onion") || ["shallot", "leek", "scallion", "chives"].contains(tag.id):
            return (
                "\(tag.displayName.capitalized) is a concentrated allium.",
                "A pinch of powder still shows up for a lot of sensitive guts.",
                "Powder and oil stay a skip. Green onion is the gentler cousin."
            )
        case "fructan" where ["wheat", "durum", "couscous", "spelt", "farro", "rye", "barley"].contains(tag.id):
            return (
                "\(tag.displayName.capitalized) is a wheat-family grain.",
                "It sits high on many labels, and late in the list is a smaller hit.",
                "Late on a packaged label is the small serve. A sandwich is not."
            )
        case "fructan" where tag.id == "inulin" || tag.id == "jerusalem_artichoke":
            return (
                "Inulin is a fiber added to a lot of “high-fiber” foods.",
                "It is easy to miss on a label and easy to notice later.",
                "There isn’t a comfortable small serve for inulin in v1 — treat it as a skip."
            )
        default:
            return (
                "\(tag.displayName.capitalized) is on AisleOK’s trigger list.",
                "Some people with a sensitive gut notice it more than others.",
                "Small means a modest serve, not a full portion."
            )
        }
    }
}
