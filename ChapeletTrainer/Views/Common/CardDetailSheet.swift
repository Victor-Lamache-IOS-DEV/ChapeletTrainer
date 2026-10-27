import SwiftUI
import SwiftData

public struct CardDetailSheet: View {
    @Bindable public var progress: CardProgress
    @Environment(\.dismiss) private var dismiss

    public init(progress: CardProgress) {
        self.progress = progress
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let card = progress.card {
                        // Carte en grand
                        VStack(spacing: 12) {
                            CardView(card: card, cornerRadius: 16)
                                .frame(width: 170)
                                .padding(.top, 10)

                            VStack(spacing: 4) {
                                Text(card.displayName)
                                    .font(.system(.title2, design: .rounded).weight(.bold))
                                    .foregroundStyle(.primary)

                                Text("Position n°\(progress.position) dans le chapelet")
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Section Indice / Phrase mnémotechnique
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Indice mnémotechnique", systemImage: "lightbulb.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("Tapez une phrase ou un mot-repère...", text: $progress.mnemonic, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)

                    // Section Statistiques
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Statistiques d'apprentissage", systemImage: "chart.bar.xaxis")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            // Statut
                            HStack {
                                Text("Niveau de maîtrise")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                statusBadge
                            }

                            Divider()

                            // Taux de réussite récent
                            HStack {
                                Text("Taux récent (10 derniers)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(progress.recentResults.isEmpty ? "—" : String(format: "%.0f %%", progress.recentSuccessRate * 100))
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                    .foregroundStyle(rateColor(progress.recentSuccessRate))
                            }

                            Divider()

                            // 10 dernières réponses
                            VStack(alignment: .leading, spacing: 8) {
                                Text("10 dernières réponses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 6) {
                                    ForEach(0..<10, id: \.self) { index in
                                        if index < progress.recentResults.count {
                                            let isCorrect = progress.recentResults[index]
                                            Circle()
                                                .fill(isCorrect ? Color.green : Color.red)
                                                .frame(width: 14, height: 14)
                                        } else {
                                            Circle()
                                                .fill(Color.gray.opacity(0.25))
                                                .frame(width: 14, height: 14)
                                        }
                                    }
                                    Spacer()
                                }
                            }

                            Divider()

                            // Compteurs
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Bonnes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(progress.correctCount)")
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                        .foregroundStyle(.green)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Erreurs")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(progress.wrongCount)")
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                        .foregroundStyle(.red)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Total essais")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(progress.totalAttempts)")
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                }
                            }

                            if let last = progress.lastSeen {
                                Divider()
                                HStack {
                                    Text("Dernière révision")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(last, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(last, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Fiche Carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if progress.recentResults.isEmpty {
            Text("Jamais testée")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
                .foregroundStyle(.secondary)
        } else if progress.isMastered {
            Text("Maîtrisée")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.2)))
                .foregroundStyle(.green)
        } else if progress.isWeak {
            Text("À travailler")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.red.opacity(0.2)))
                .foregroundStyle(.red)
        } else {
            Text("En cours")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.orange.opacity(0.2)))
                .foregroundStyle(.orange)
        }
    }

    private func rateColor(_ rate: Double) -> Color {
        if rate >= 0.8 { return .green }
        if rate >= 0.5 { return .orange }
        return .red
    }
}
