import Foundation

struct OFFProduct: Equatable {
    var code: String
    var name: String
    var ingredients: String?
    var pageURL: URL

    var hasIngredients: Bool {
        guard let ingredients else { return false }
        return !ingredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum OpenFoodFactsClient {
    static let userAgent = "AisleOK/1.0 (https://github.com/TonBorrellEmbat/aisleok)"

    /// One live GET per real scan. No cache.
    static func fetch(code raw: String) async throws -> OFFProduct? {
        let code = normalizedCode(raw)
        var request = URLRequest(url: endpoint(code: code))
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            return nil
        }
        let decoded = try JSONDecoder().decode(V3Response.self, from: data)
        guard decoded.status == "success", let product = decoded.product else {
            return nil
        }
        let name = displayName(product)
        let ingredients = firstNonEmpty(product.ingredientsTextEn, product.ingredientsText)
        return OFFProduct(
            code: product.code ?? code,
            name: name,
            ingredients: ingredients,
            pageURL: URL(string: "https://world.openfoodfacts.org/product/\(product.code ?? code)")!
        )
    }

    static func pageURL(code: String) -> URL {
        URL(string: "https://world.openfoodfacts.org/product/\(normalizedCode(code))")!
    }

    /// Single call: pad 12-digit UPC-A to EAN-13. Leave EAN-8 / UPC-E as scanned.
    static func normalizedCode(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        if digits.count == 12 {
            return "0" + digits
        }
        return digits
    }

    private static func endpoint(code: String) -> URL {
        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v3/product/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "product_name,brands,code,ingredients_text,ingredients_text_en")
        ]
        return components.url!
    }

    private static func displayName(_ product: V3Product) -> String {
        let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !name.isEmpty { return name }
        let brands = product.brands?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !brands.isEmpty { return brands }
        return product.code ?? "Scanned item"
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }

    private struct V3Response: Decodable {
        var status: String?
        var product: V3Product?
    }

    private struct V3Product: Decodable {
        var code: String?
        var productName: String?
        var brands: String?
        var ingredientsText: String?
        var ingredientsTextEn: String?

        enum CodingKeys: String, CodingKey {
            case code, brands
            case productName = "product_name"
            case ingredientsText = "ingredients_text"
            case ingredientsTextEn = "ingredients_text_en"
        }
    }
}
