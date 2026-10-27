import SwiftUI

public struct TestResultView: View {
    public let results: [TestQuestionResult]
    public let duration: Double
    public let onRetryErrors: ([Int]) -> Void
    public let onFinish: () -> Void

    public init(
        results: [TestQuestionResult],
        duration: Double,
        onRetryErrors: @escaping ([Int]) -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.results = results
        self.duration = duration
        self.onRetryErrors = onRetryErrors
        self.onFinish = onFinish
    }

    private var correctCount: Int {
        results.filter { $0.isCorrect }.count
    }

    private var totalCount: Int {
        results.count
    }

    private var successPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return (Double(correctCount) / Double(totalCount)) * 100.0
    }

    private var errorResults: [TestQuestionResult] {
        results.filter { !$0.isCorrect }
    }

    private var errorPositions: [Int] {
        Array(Set(errorResults.map { $0.position })).sorted()
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Carte Score
                    scoreCard
                        .padding(.top, 10)

                    // Liste des erreurs
                    if !errorResults.isEmpty {
                        errorsSection
                    } else {
                        perfectScoreBanner
                    }

                    // Boutons d'action
                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Résultats du test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminer") {
                        onFinish()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Carte Score
    private var scoreCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(successPercentage / 100.0))
                    .stroke(
                        successPercentage >= 80 ? Color.green : (successPercentage >= 50 ? Color.orange : Color.red),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)

                VStack(spacing: 0) {
                    Text(String(format: "%.0f%%", successPercentage))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("\(correctCount)/\(totalCount)")
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundStyle(.secondary)
                    Text(formattedDuration(duration))
                        .font(.system(.footnote, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("\(errorResults.count) erreur\(errorResults.count > 1 ? "s" : "")")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - Section Erreurs
    private var errorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Erreurs à revoir (\(errorPositions.count) carte\(errorPositions.count > 1 ? "s" : ""))")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                ForEach(errorResults) { err in
                    HStack(spacing: 12) {
                        CardView(card: err.card, cornerRadius: 4)
                            .frame(width: 38, height: 53)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(err.card.displayName)
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                Spacer()
                                Text("Pos. #\(err.position)")
                                    .font(.system(.caption, design: .monospaced).weight(.bold))
                                    .foregroundStyle(Color.accentColor)
                            }

                            Text("Votre réponse : \(err.userGuess)")
                                .font(.caption)
                                .foregroundStyle(.red)

                            if !err.mnemonic.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                    Text(err.mnemonic)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }
            }
        }
    }

    private var perfectScoreBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)

            Text("Sans faute !")
                .font(.system(.title3, design: .rounded).weight(.heavy))

            Text("Vous avez répondu correctement à toutes les cartes sélectionnées.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if !errorPositions.isEmpty {
                Button {
                    Haptics.shared.medium()
                    onRetryErrors(errorPositions)
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Refaire avec les erreurs (\(errorPositions.count))")
                    }
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }

            Button {
                onFinish()
            } label: {
                Text("Terminer le test")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(uiColor: .secondarySystemFill))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.top, 8)
    }

    private func formattedDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        if m > 0 {
            return String(format: "%d min %02d s", m, s)
        } else {
            return String(format: "%d s", s)
        }
    }
}
