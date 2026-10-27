import Foundation
import SwiftData

public final class DeckStore {
    @MainActor
    public static func ensureInitialized(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<CardProgress>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        if existing.count < 52 {
            let existingPositions = Set(existing.map { $0.position })
            for pos in 1...52 {
                if !existingPositions.contains(pos) {
                    let progress = CardProgress(position: pos, mnemonic: "", isKnown: true)
                    modelContext.insert(progress)
                }
            }
            try? modelContext.save()
        }
    }

    /// Tirage pondéré : les cartes avec un fort taux d'erreur récent reviennent plus souvent.
    /// Le temps de réponse n'est JAMAIS pris en compte.
    public static func pickNextQuestion(
        from candidates: [Int],
        progressMap: [Int: CardProgress],
        lastPickedPosition: Int?
    ) -> Int? {
        guard !candidates.isEmpty else { return nil }

        // Si une seule carte est sélectionnée, on n'a pas le choix
        if candidates.count == 1 {
            return candidates[0]
        }

        // On filtre la dernière carte pour éviter deux questions identiques consécutives
        let eligible = candidates.filter { $0 != lastPickedPosition }
        let pool = eligible.isEmpty ? candidates : eligible

        // Calcul des poids
        var weightedList: [(position: Int, weight: Double)] = []
        for pos in pool {
            let progress = progressMap[pos]
            let weight: Double
            if let p = progress, !p.recentResults.isEmpty {
                // Taux d'erreur entre 0.0 et 1.0 -> poids entre 1.0 et 4.0
                let errorRate = p.recentErrorRate
                weight = 1.0 + (errorRate * 3.0)
            } else {
                // Jamais testé : poids modéré pour découverte
                weight = 2.0
            }
            weightedList.append((pos, weight))
        }

        let totalWeight = weightedList.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return pool.randomElement() }

        var randomValue = Double.random(in: 0..<totalWeight)
        for item in weightedList {
            if randomValue < item.weight {
                return item.position
            }
            randomValue -= item.weight
        }

        return pool.last
    }

    /// Réinitialisation complète de toutes les statistiques
    @MainActor
    public static func resetAllStats(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<CardProgress>()
        if let allProgress = try? modelContext.fetch(descriptor) {
            for p in allProgress {
                p.resetStats()
            }
        }

        let sessionDescriptor = FetchDescriptor<TestSession>()
        if let allSessions = try? modelContext.fetch(sessionDescriptor) {
            for s in allSessions {
                modelContext.delete(s)
            }
        }

        try? modelContext.save()
    }
}
