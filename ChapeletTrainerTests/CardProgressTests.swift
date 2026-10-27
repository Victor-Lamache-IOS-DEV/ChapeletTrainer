import XCTest
@testable import ChapeletTrainer

final class CardProgressTests: XCTestCase {

    func testInitialProgressState() {
        let progress = CardProgress(position: 1)
        XCTAssertEqual(progress.position, 1)
        XCTAssertEqual(progress.mnemonic, "")
        XCTAssertTrue(progress.isKnown)
        XCTAssertEqual(progress.correctCount, 0)
        XCTAssertEqual(progress.wrongCount, 0)
        XCTAssertTrue(progress.recentResults.isEmpty)
        XCTAssertNil(progress.lastSeen)
        XCTAssertEqual(progress.heatmapStatus, .unrecorded)
        XCTAssertTrue(progress.isWeak, "Une carte jamais testée doit être considérée comme faible.")
        XCTAssertFalse(progress.isMastered, "Une carte jamais testée ne peut pas être maîtrisée.")
    }

    func testRecordAnswerSlidingWindow() {
        let progress = CardProgress(position: 10)

        // Enregistrer 12 réponses
        for _ in 1...10 {
            progress.recordAnswer(isCorrect: true)
        }
        XCTAssertEqual(progress.recentResults.count, 10)
        XCTAssertEqual(progress.recentSuccessRate, 1.0)
        XCTAssertTrue(progress.isMastered)

        // Deux erreurs supplémentaires
        progress.recordAnswer(isCorrect: false)
        progress.recordAnswer(isCorrect: false)

        XCTAssertEqual(progress.recentResults.count, 10, "La fenêtre glissante doit conserver au plus 10 réponses.")
        XCTAssertEqual(progress.correctCount, 10)
        XCTAssertEqual(progress.wrongCount, 2)
        XCTAssertEqual(progress.totalAttempts, 12)
        XCTAssertEqual(progress.recentSuccessRate, 0.8, accuracy: 0.001) // 8 bonnes sur 10
        XCTAssertTrue(progress.isMastered)
    }

    func testMasteryCriteria() {
        let progress = CardProgress(position: 5)

        // 4 réponses correctes consécutives (100% mais moins de 5 essais)
        for _ in 1...4 {
            progress.recordAnswer(isCorrect: true)
        }
        XCTAssertFalse(progress.isMastered, "Une carte nécessite au moins 5 réponses pour être maîtrisée.")

        // 5ème réponse correcte
        progress.recordAnswer(isCorrect: true)
        XCTAssertTrue(progress.isMastered, "5 réponses avec 100% de réussite = maîtrisée.")

        // Deux erreurs -> 5 réussites, 2 erreurs -> 5/7 = 71.4% < 80%
        progress.recordAnswer(isCorrect: false)
        progress.recordAnswer(isCorrect: false)
        XCTAssertFalse(progress.isMastered, "Taux < 80% ne doit plus être maîtrisée.")
    }

    func testWeakCardCriteria() {
        let progress = CardProgress(position: 12)
        XCTAssertTrue(progress.isWeak, "Jamais testée = faible.")

        // 10 réponses avec 6 réussites (60% < 70%)
        for _ in 1...6 { progress.recordAnswer(isCorrect: true) }
        for _ in 1...4 { progress.recordAnswer(isCorrect: false) }
        XCTAssertTrue(progress.isWeak, "60% < 70% = carte faible.")

        // 4 réussites de plus -> fenêtre glissante : 6 réussites précédentes disparaissent ou se renouvellent
        for _ in 1...4 { progress.recordAnswer(isCorrect: true) } // fenetre : 2xV, 4xF, 4xV -> 6/10 = 60%
        for _ in 1...3 { progress.recordAnswer(isCorrect: true) } // 7/10 ou 8/10
        XCTAssertFalse(progress.isWeak)
    }

    func testHeatmapStatusThresholds() {
        let p = CardProgress(position: 1)
        XCTAssertEqual(p.heatmapStatus, .unrecorded)

        // Moins de 50%
        p.recordAnswer(isCorrect: false)
        XCTAssertEqual(p.heatmapStatus, .lowSuccess)
        XCTAssertTrue(p.isLowSample, "1 réponse < 3 tests -> isLowSample = true")

        // 50% à 79%
        p.recordAnswer(isCorrect: true) // 1/2 = 50%
        XCTAssertEqual(p.heatmapStatus, .mediumSuccess)

        // >= 80%
        p.recordAnswer(isCorrect: true)
        p.recordAnswer(isCorrect: true)
        p.recordAnswer(isCorrect: true) // 4/5 = 80%
        XCTAssertEqual(p.heatmapStatus, .highSuccess)
        XCTAssertFalse(p.isLowSample, "5 réponses >= 3 -> isLowSample = false")
    }
}
