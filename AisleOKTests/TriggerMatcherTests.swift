import XCTest
@testable import AisleOK

final class TriggerMatcherTests: XCTestCase {
    var matcher: TriggerMatcher!

    override func setUpWithError() throws {
        let url = Bundle(for: TriggerMatcherTests.self).url(forResource: "AisleOK_trigger_tags_v1", withExtension: "json")
            ?? Bundle.main.url(forResource: "AisleOK_trigger_tags_v1", withExtension: "json")
        let tags = try TriggerCatalog.load(from: XCTUnwrap(url))
        XCTAssertFalse(tags.isEmpty, "trigger JSON missing from test bundle")
        matcher = TriggerMatcher(tags: tags)
    }

    func testSoybeanOilIsNotSoybeans() {
        let r = matcher.scoreIngredients("soybean oil, water, salt")
        XCTAssertEqual(r.band, .eat)
        XCTAssertNil(r.tagId)
    }

    func testMayoWithSoybeanOilIsEat() {
        let r = matcher.scoreIngredients("Soybean Oil, Water, Whole Eggs, Egg Yolks, Distilled Vinegar, Salt, Sugar, Lemon Juice Concentrate, Natural Flavors")
        XCTAssertEqual(r.band, .eat)
    }

    func testAlmondMilkIsNotMilkSkip() {
        let r = matcher.scoreIngredients("almond milk, water, sugar")
        XCTAssertNotEqual(r.tagId, "milk")
        XCTAssertNotEqual(r.band, .skip)
    }

    func testOatMilkIsNotMilkSkip() {
        let r = matcher.scoreIngredients("oat milk, water")
        XCTAssertNotEqual(r.tagId, "milk")
        XCTAssertNotEqual(r.band, .skip)
    }

    func testCheeriosOatsEat() {
        let r = matcher.scoreIngredients("Whole Grain Oats, Corn Starch, Sugar, Salt, Tripotassium Phosphate")
        XCTAssertEqual(r.band, .eat)
        XCTAssertEqual(r.tagId, "oats")
    }

    func testCornStarchIsNotCorn() {
        let r = matcher.scoreIngredients("water, corn starch, salt")
        XCTAssertNotEqual(r.tagId, "corn")
    }

    func testJifPeanutsEat() {
        let r = matcher.scoreIngredients("Roasted Peanuts, Sugar, Contains 2% or Less of Molasses, Fully Hydrogenated Vegetable Oils (Rapeseed and Soybean), Mono and Diglycerides, Salt")
        XCTAssertEqual(r.band, .eat)
        XCTAssertEqual(r.tagId, "peanuts")
    }

    func testBroccoliSmall() {
        let r = matcher.scoreName("broccoli")
        XCTAssertEqual(r.band, .small)
        XCTAssertEqual(r.tagId, "broccoli")
    }

    func testGarlicPowderSkipEvenLate() {
        let r = matcher.scoreIngredients("water, salt, sugar, vinegar, citric acid, garlic powder")
        XCTAssertEqual(r.band, .skip)
        XCTAssertEqual(r.tagId, "garlic_powder")
    }

    func testTopFiveUsesDefaultBand() {
        let top = matcher.scoreIngredients("milk, water, salt")
        XCTAssertEqual(top.band, .skip)
        XCTAssertEqual(top.tagId, "milk")
    }

    func testLateBandForMilk() {
        let late = matcher.scoreIngredients("water, salt, sugar, oil, vinegar, milk")
        XCTAssertEqual(late.band, .small)
        XCTAssertEqual(late.tagId, "milk")
    }

    func testSkipBeatsSmallBeatsEat() {
        let r = matcher.scoreIngredients("oats, broccoli, garlic")
        XCTAssertEqual(r.band, .skip)
        XCTAssertEqual(r.tagId, "garlic")
    }

    func testNoNaturalFlavorInference() {
        let r = matcher.scoreIngredients("water, salt, natural flavors")
        XCTAssertEqual(r.band, .eat)
        XCTAssertNil(r.tagId)
    }

    func testEmptyIngredientsUnknown() {
        XCTAssertEqual(matcher.scoreIngredients(nil).band, .unknown)
        XCTAssertEqual(matcher.scoreIngredients("   ").band, .unknown)
    }

    func testLongestAliasWinsGarlicPowderOverGarlic() {
        let r = matcher.scoreIngredients("garlic powder")
        XCTAssertEqual(r.tagId, "garlic_powder")
    }

    func testWholeTokenSoybeansStillMatches() {
        let r = matcher.scoreIngredients("soybeans, salt")
        XCTAssertEqual(r.tagId, "soy_bean")
        XCTAssertEqual(r.band, .skip)
    }
}

final class OpenFoodFactsTests: XCTestCase {
    func testUserAgentIsSet() {
        XCTAssertTrue(OpenFoodFactsClient.userAgent.contains("AisleOK"))
        XCTAssertTrue(OpenFoodFactsClient.userAgent.contains("github.com/TonBorrellEmbat/aisleok"))
    }

    func testLooksWrongKeepsName() {
        var item = ScanOutcome(
            id: UUID(),
            productName: "Chobani Vanilla",
            score: ScoreResult(band: .skip, displayName: "pork", tagId: nil, category: nil, detail: "pork", doseLine: nil),
            offCode: "0037600115445",
            offURL: nil,
            source: .barcode,
            looksWrongApplied: false
        )
        item.applyLooksWrong()
        XCTAssertEqual(item.productName, "Chobani Vanilla")
        XCTAssertEqual(item.score.band, .unknown)
        XCTAssertTrue(item.looksWrongApplied)
    }
}
