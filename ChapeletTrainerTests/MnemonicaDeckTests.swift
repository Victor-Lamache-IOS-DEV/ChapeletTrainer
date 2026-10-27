import XCTest
@testable import ChapeletTrainer

final class MnemonicaDeckTests: XCTestCase {

    func testMnemonicaDeckContainsExactly52Cards() {
        XCTAssertEqual(MnemonicaDeck.cards.count, 52, "Le chapelet Mnemonica doit contenir exactement 52 cartes.")
    }

    func testMnemonicaDeckContainsAllUniqueCards() {
        let uniqueCards = Set(MnemonicaDeck.cards)
        XCTAssertEqual(uniqueCards.count, 52, "Toutes les 52 cartes du chapelet doivent être uniques (aucun doublon).")
    }

    func testMnemonicaKnownLandmarks() {
        // Position 1 : 4 de trèfle (4C)
        let firstCard = MnemonicaDeck.card(at: 1)
        XCTAssertNotNil(firstCard)
        XCTAssertEqual(firstCard?.rank, .four)
        XCTAssertEqual(firstCard?.suit, .clubs)
        XCTAssertEqual(firstCard?.assetName, "4C")

        // Position 7 : As de pique (AS)
        let seventhCard = MnemonicaDeck.card(at: 7)
        XCTAssertNotNil(seventhCard)
        XCTAssertEqual(seventhCard?.rank, .ace)
        XCTAssertEqual(seventhCard?.suit, .spades)
        XCTAssertEqual(seventhCard?.assetName, "AS")

        // Position 26 : Roi de carreau (KD)
        let middleCard = MnemonicaDeck.card(at: 26)
        XCTAssertNotNil(middleCard)
        XCTAssertEqual(middleCard?.rank, .king)
        XCTAssertEqual(middleCard?.suit, .diamonds)
        XCTAssertEqual(middleCard?.assetName, "KD")

        // Position 52 : 9 de carreau (9D)
        let lastCard = MnemonicaDeck.card(at: 52)
        XCTAssertNotNil(lastCard)
        XCTAssertEqual(lastCard?.rank, .nine)
        XCTAssertEqual(lastCard?.suit, .diamonds)
        XCTAssertEqual(lastCard?.assetName, "9D")
    }

    func testCardLookupPosition() {
        guard let card1 = MnemonicaDeck.card(at: 1) else {
            XCTFail("Carte 1 introuvable")
            return
        }
        XCTAssertEqual(MnemonicaDeck.position(of: card1), 1)

        guard let card52 = MnemonicaDeck.card(at: 52) else {
            XCTFail("Carte 52 introuvable")
            return
        }
        XCTAssertEqual(MnemonicaDeck.position(of: card52), 52)

        // Hors limites
        XCTAssertNil(MnemonicaDeck.card(at: 0))
        XCTAssertNil(MnemonicaDeck.card(at: 53))
    }

    func testSortedBySuitAndRankGrid() {
        let sortedDeck = MnemonicaDeck.sortedBySuitAndRank
        XCTAssertEqual(sortedDeck.count, 52)
        XCTAssertEqual(Set(sortedDeck).count, 52)

        // Vérifier que ce n'est PAS l'ordre du chapelet
        XCTAssertNotEqual(sortedDeck, MnemonicaDeck.cards)
    }
}
