import Foundation
import SwiftData

public enum HeatmapStatus: String, Sendable {
    case unrecorded
    case lowSuccess     // < 50%
    case mediumSuccess  // 50% .. 79%
    case highSuccess    // >= 80%
}

@Model
public final class CardProgress {
    @Attribute(.unique) public var position: Int
    public var mnemonic: String
    public var isKnown: Bool
    public var correctCount: Int
    public var wrongCount: Int
    public var recentResults: [Bool]
    public var lastSeen: Date?

    public init(
        position: Int,
        mnemonic: String = "",
        isKnown: Bool = true,
        correctCount: Int = 0,
        wrongCount: Int = 0,
        recentResults: [Bool] = [],
        lastSeen: Date? = nil
    ) {
        self.position = position
        self.mnemonic = mnemonic
        self.isKnown = isKnown
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.recentResults = recentResults
        self.lastSeen = lastSeen
    }

    /// Carte associée dans le chapelet
    public var card: Card? {
        MnemonicaDeck.card(at: position)
    }

    /// Nombre total d'essais
    public var totalAttempts: Int {
        correctCount + wrongCount
    }

    /// Taux global de réussite
    public var globalSuccessRate: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(correctCount) / Double(totalAttempts)
    }

    /// Taux de réussite calculé uniquement sur les 10 dernières réponses
    public var recentSuccessRate: Double {
        guard !recentResults.isEmpty else { return 0.0 }
        let correct = recentResults.filter { $0 }.count
        return Double(correct) / Double(recentResults.count)
    }

    /// Taux d'erreur récent (utilisé pour le tirage pondéré et le classement des difficultés)
    public var recentErrorRate: Double {
        guard !recentResults.isEmpty else { return 0.5 } // Jamais testé = neutral/moderate
        return 1.0 - recentSuccessRate
    }

    /// Carte maîtrisée : au moins 5 réponses et 80% ou plus sur les 10 dernières
    public var isMastered: Bool {
        recentResults.count >= 5 && recentSuccessRate >= 0.8
    }

    /// Carte faible : moins de 70% de réussite sur les 10 dernières, ou jamais testée
    public var isWeak: Bool {
        recentResults.isEmpty || recentSuccessRate < 0.7
    }

    /// Statut pour la coloration Heatmap
    public var heatmapStatus: HeatmapStatus {
        if recentResults.isEmpty {
            return .unrecorded
        }
        let rate = recentSuccessRate
        if rate < 0.5 {
            return .lowSuccess
        } else if rate < 0.8 {
            return .mediumSuccess
        } else {
            return .highSuccess
        }
    }

    /// Indique si la carte a été testée moins de 3 fois (affichera un repère discret sur la heatmap)
    public var isLowSample: Bool {
        !recentResults.isEmpty && recentResults.count < 3
    }

    /// Enregistre une nouvelle réponse sans JAMAIS prendre en compte la durée
    public func recordAnswer(isCorrect: Bool) {
        if isCorrect {
            correctCount += 1
        } else {
            wrongCount += 1
        }

        recentResults.append(isCorrect)
        if recentResults.count > 10 {
            recentResults.removeFirst()
        }
        lastSeen = Date()
    }

    /// Réinitialise les statistiques tout en préservant le mnémonique et la sélection
    public func resetStats() {
        correctCount = 0
        wrongCount = 0
        recentResults = []
        lastSeen = nil
    }
}
