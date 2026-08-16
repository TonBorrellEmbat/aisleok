import SwiftUI
import UIKit

enum AisleOKColor {
    static let paprika = Color(red: 201 / 255, green: 74 / 255, blue: 42 / 255)
    static let clay = Color(red: 196 / 255, green: 90 / 255, blue: 58 / 255)
    static let sand = Color(red: 196 / 255, green: 180 / 255, blue: 154 / 255)

    /// Eat word only. Cream-tinted in Dark Mode so it stays readable.
    static let cocoa = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.90, green: 0.82, blue: 0.72, alpha: 1)
        }
        return UIColor(red: 43 / 255, green: 26 / 255, blue: 18 / 255, alpha: 1)
    })

    /// Cream wash in light mode; system background in dark.
    static let canvas = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return .systemBackground
        }
        return UIColor(red: 246 / 255, green: 239 / 255, blue: 227 / 255, alpha: 1)
    })
}

enum Band: String, Codable, Comparable, Hashable {
    case eat, small, skip, unknown

    private var rank: Int {
        switch self {
        case .unknown: return 0
        case .eat: return 1
        case .small: return 2
        case .skip: return 3
        }
    }

    static func < (lhs: Band, rhs: Band) -> Bool { lhs.rank < rhs.rank }

    var word: String {
        switch self {
        case .eat: return "Eat"
        case .small: return "Small portion"
        case .skip: return "Skip"
        case .unknown: return "Unknown"
        }
    }

    var wordColor: Color {
        switch self {
        case .eat: return AisleOKColor.cocoa
        case .small: return AisleOKColor.paprika
        case .skip: return AisleOKColor.clay
        case .unknown: return AisleOKColor.sand
        }
    }
}

enum AisleOKLinks {
    static let privacy = URL(string: "https://tonborrellembat.github.io/aisleok/privacy.html")!
    static let terms = URL(string: "https://tonborrellembat.github.io/aisleok/terms.html")!
}

enum StoreProductID {
    static let yearly = "yearly.4999"
    static let monthly = "monthly.999"
    static let all = [yearly, monthly]
}
