import SwiftUI
import SwiftData
import Charts

public struct StatsView: View {
    @Query(sort: \CardProgress.position, order: .forward) private var progressItems: [CardProgress]
    @Query(sort: \TestSession.date, order: .forward) private var testSessions: [TestSession]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCardProgress: CardProgress?
    @State private var showingResetConfirmation: Bool = false
    @State private var showingAboutSheet: Bool = false

    private let heatmapColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    public init() {}

    // MARK: - Métriques calculées
    private var globalSuccessRate: Double {
        let total = progressItems.reduce(0) { $0 + $1.totalAttempts }
        let correct = progressItems.reduce(0) { $0 + $1.correctCount }
        guard total > 0 else { return 0 }
        return (Double(correct) / Double(total)) * 100.0
    }

    private var masteredCardsCount: Int {
        progressItems.filter { $0.isMastered }.count
    }

    private var topDifficultCards: [CardProgress] {
        progressItems
            .filter { $0.totalAttempts > 0 && ($0.wrongCount > 0 || $0.recentSuccessRate < 1.0) }
            .sorted { (lhs, rhs) -> Bool in
                if lhs.recentErrorRate != rhs.recentErrorRate {
                    return lhs.recentErrorRate > rhs.recentErrorRate
                }
                return lhs.wrongCount > rhs.wrongCount
            }
            .prefix(10)
            .map { $0 }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // 1. Vue d'ensemble (3 cartes métriques)
                    overviewMetrics

                    // 2. Heatmap des 52 cartes
                    heatmapSection

                    // 3. Top 10 des cartes difficiles
                    topDifficultSection

                    // 4. Graphique de progression par session
                    progressionChartSection

                    // 5. Zone Danger / Réinitialisation
                    resetSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 36)
            }
            .navigationTitle("Statistiques")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAboutSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(item: $selectedCardProgress) { progress in
                CardDetailSheet(progress: progress)
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutSheet()
            }
            .confirmationDialog(
                "Réinitialiser toutes les statistiques ?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Tout effacer", role: .destructive) {
                    DeckStore.resetAllStats(modelContext: modelContext)
                    Haptics.shared.warning()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action effacera l'historique de vos sessions et les compteurs de réussite, mais conservera vos phrases mnémotechniques.")
            }
        }
    }

    // MARK: - 1. Vue d'ensemble
    private var overviewMetrics: some View {
        HStack(spacing: 10) {
            metricCard(
                title: "Réussite",
                value: String(format: "%.0f%%", globalSuccessRate),
                icon: "percent",
                color: Color.accentColor
            )

            metricCard(
                title: "Sessions",
                value: "\(testSessions.count)",
                icon: "checkmark.seal.fill",
                color: Color.blue
            )

            metricCard(
                title: "Maîtrisées",
                value: "\(masteredCardsCount)/52",
                icon: "crown.fill",
                color: Color.green
            )
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Spacer()
            }

            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - 2. Heatmap des 52 cartes
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Heatmap du Chapelet", systemImage: "square.grid.3x3.fill")
                    .font(.system(.headline, weight: .bold, design: .rounded))
                Spacer()
                Text("Dans l'ordre 1 à 52")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: heatmapColumns, spacing: 6) {
                ForEach(progressItems) { item in
                    heatmapCell(item: item)
                }
            }

            // Légende Heatmap
            heatmapLegend
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func heatmapCell(item: CardProgress) -> some View {
        Button {
            selectedCardProgress = item
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(heatmapColor(for: item.heatmapStatus))
                    .aspectRatio(1.0, contentMode: .fit)

                VStack(spacing: 1) {
                    Text("\(item.position)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)

                    if let card = item.card {
                        Text(card.shortName)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Indicateur discret si testée moins de 3 fois
                if item.isLowSample {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                        .offset(x: -3, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func heatmapColor(for status: HeatmapStatus) -> Color {
        switch status {
        case .unrecorded:
            return Color(white: 0.28)
        case .lowSuccess:
            return Color(red: 0.90, green: 0.22, blue: 0.22) // Rouge < 50%
        case .mediumSuccess:
            return Color.orange                              // Orange 50-79%
        case .highSuccess:
            return Color(red: 0.18, green: 0.78, blue: 0.35) // Vert >= 80%
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 10) {
            legendItem(color: Color(white: 0.28), label: "Jamais")
            legendItem(color: Color(red: 0.90, green: 0.22, blue: 0.22), label: "< 50%")
            legendItem(color: Color.orange, label: "50-79%")
            legendItem(color: Color(red: 0.18, green: 0.78, blue: 0.35), label: "≥ 80%")

            Spacer()

            HStack(spacing: 4) {
                Circle().fill(Color.white).frame(width: 5, height: 5)
                Text("< 3 tests")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 3. Top 10 Cartes Difficiles
    private var topDifficultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top 10 des cartes difficiles", systemImage: "exclamationmark.triangle.fill")
                .font(.system(.headline, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            if topDifficultCards.isEmpty {
                Text("Aucune difficulté enregistrée pour le moment. Félicitations !")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(topDifficultCards) { progress in
                        if let card = progress.card {
                            Button {
                                selectedCardProgress = progress
                            } label: {
                                HStack(spacing: 12) {
                                    CardView(card: card, cornerRadius: 4)
                                        .frame(width: 32, height: 45)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(card.displayName)
                                                .font(.system(.subheadline, weight: .bold, design: .rounded))
                                            Spacer()
                                            Text("Pos. #\(progress.position)")
                                                .font(.system(.caption, weight: .bold, design: .monospaced))
                                                .foregroundStyle(Color.accentColor)
                                        }

                                        HStack(spacing: 10) {
                                            Text("Erreurs récentes : \(String(format: "%.0f%%", progress.recentErrorRate * 100))")
                                                .font(.caption2)
                                                .foregroundStyle(.red)

                                            Text("Total erreurs : \(progress.wrongCount)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        if !progress.mnemonic.isEmpty {
                                            Text("💡 \(progress.mnemonic)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - 4. Graphique Swift Charts
    private var progressionChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Progression par session", systemImage: "chart.xyaxis.line")
                .font(.system(.headline, weight: .bold, design: .rounded))

            if testSessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Aucune session enregistrée")
                        .font(.subheadline.bold())
                    Text("Terminez votre premier entraînement pour visualiser votre courbe d'apprentissage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(Array(testSessions.enumerated()), id: \.offset) { index, session in
                        LineMark(
                            x: .value("Session", index + 1),
                            y: .value("Taux", session.successRate * 100.0)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)

                        PointMark(
                            x: .value("Session", index + 1),
                            y: .value("Taux", session.successRate * 100.0)
                        )
                        .foregroundStyle(Color.accentColor)
                    }

                    RuleMark(y: .value("Objectif Maîtrise", 80))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color.green.opacity(0.6))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Maîtrise 80%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                        }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { val in
                        AxisValueLabel {
                            if let intVal = val.as(Int.self) {
                                Text("\(intVal)%")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { val in
                        AxisValueLabel {
                            if let s = val.as(Int.self) {
                                Text("S\(s)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - 5. Réinitialisation
    private var resetSection: some View {
        Button(role: .destructive) {
            showingResetConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Réinitialiser les statistiques")
            }
            .font(.system(.subheadline, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Color.red.opacity(0.12))
            .foregroundStyle(.red)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
