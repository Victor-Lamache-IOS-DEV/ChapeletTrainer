import XCTest
@testable import ChapeletTrainer

final class DeckStoreTests: XCTestCase {

    func testWeightedPickerReturnsValidCandidate() {
        let candidates = [1, 2, 3, 4]
        let p1 = CardProgress(position: 1)
        let p2 = CardProgress(position: 2)
        let p3 = CardProgress(position: 3)
        let p4 = CardProgress(position: 4)

        // p1 a 100% d'erreurs
        p1.recordAnswer(isCorrect: false)
        p1.recordAnswer(isCorrect: false)

        // p4 a 100% de succès
        for _ in 1...5 { p4.recordAnswer(isCorrect: true) }

        let map: [Int: CardProgress] = [1: p1, 2: p2, 3: p3, 4: p4]

        var pickedStats: [Int: Int] = [:]
        for _ in 1...200 {
            if let picked = DeckStore.pickNextQuestion(from: candidates, progressMap: map, lastPickedPosition: nil) {
                pickedStats[picked, default: 0] += 1
            }
        }

        XCTAssertTrue(pickedStats[1, default: 0] > 0, "La carte avec fort taux d'erreur doit être sélectionnée.")
        XCTAssertTrue(pickedStats[1, default: 0] > pickedStats[4, default: 0], "La carte avec erreurs (p1) doit être tirée plus fréquemment que la carte maîtrisée (p4).")
    }

    func testSingleCandidateReturnsItself() {
        let single = [14]
        let map: [Int: CardProgress] = [14: CardProgress(position: 14)]
        let picked = DeckStore.pickNextQuestion(from: single, progressMap: map, lastPickedPosition: 14)
        XCTAssertEqual(picked, 14)
    }

    func testMnemonicJSONExportAndImport() {
        let progress1 = CardProgress(position: 1, mnemonic: "La bicyclette de Jean")
        let progress2 = CardProgress(position: 7, mnemonic: "As de pique magique")
        let items = [progress1, progress2]

        guard let json = MnemonicSyncService.createExportJSON(from: items) else {
            XCTFail("Export JSON failed")
            return
        }

        // Simuler nouvelle liste vierge
        let target1 = CardProgress(position: 1, mnemonic: "")
        let target2 = CardProgress(position: 7, mnemonic: "")
        let importedCount = MnemonicSyncService.importMnemonics(from: json, into: [target1, target2])

        XCTAssertEqual(importedCount, 2)
        XCTAssertEqual(target1.mnemonic, "La bicyclette de Jean")
        XCTAssertEqual(target2.mnemonic, "As de pique magique")
    }
}
