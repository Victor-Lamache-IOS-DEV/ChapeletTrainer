import SwiftUI
import SwiftData

public struct TestRootView: View {
    @Query(sort: \CardProgress.position, order: .forward) private var progressItems: [CardProgress]
    @Environment(\.modelContext) private var modelContext

    // Configuration du test
    @State private var selectedMode: TestMode = .cardToPosition
    @State private var selectedQuestionCount: QuestionCountOption = .fixed(10)
    @State private var showTimer: Bool = true

    // Gestion du flux
    @State private var isTestActive: Bool = false
    @State private var activeResults: [TestQuestionResult]?
    @State private var activeDuration: Double = 0
    @State private var isResultActive: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    public init() {}

    private var selectedCount: Int {
        progressItems.filter { $0.isKnown }.count
    }

    private var selectedPositions: [Int] {
        progressItems.filter { $0.isKnown }.map { $0.position }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Étape 2 : Réglages du test
                    settingsSection

                    // Étape 1 : Sélection des cartes
                    selectionHeaderSection

                    shortcutsView

                    selectionGrid
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 90)
            }
            .navigationTitle("Entraînement")
            .overlay(alignment: .bottom) {
                launchButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .fullScreenCover(isPresented: $isTestActive) {
                TestActiveView(
                    selectedPositions: selectedPositions,
                    configMode: selectedMode,
                    questionCountOption: selectedQuestionCount,
                    showTimer: showTimer
                ) { results, duration in
                    handleTestFinish(results: results, duration: duration)
                }
            }
            .sheet(isPresented: $isResultActive) {
                if let results = activeResults {
                    TestResultView(
                        results: results,
                        duration: activeDuration,
                        onRetryErrors: { errorPositions in
                            retryWithErrors(errorPositions)
                        },
                        onFinish: {
                            isResultActive = false
                        }
                    )
                }
            }
        }
    }

    // MARK: - Étape 2 : Réglages
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mode de test")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)

            // Sélecteur de mode
            Picker("Mode", selection: $selectedMode) {
                ForEach(TestMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Sélecteur nombre de questions
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre de questions")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(QuestionCountOption.defaults) { opt in
                        Button {
                            Haptics.shared.selection()
                            selectedQuestionCount = opt
                        } label: {
                            Text(opt.title)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(selectedQuestionCount == opt ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                                .foregroundStyle(selectedQuestionCount == opt ? Color.white : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Option Chronomètre
            Toggle(isOn: $showTimer) {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Afficher le chronomètre")
                            .font(.system(.body, design: .rounded).weight(.medium))
                        Text("Purement indicatif, n'influence aucune statistique")
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - Étape 1 : Sélection & Raccourcis
    private var selectionHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Cartes à réviser")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Text("Touchez une carte pour l'inclure ou la retirer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(selectedCount) / 52")
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(selectedCount > 0 ? Color.accentColor.opacity(0.18) : Color.red.opacity(0.18))
                )
                .foregroundStyle(selectedCount > 0 ? Color.accentColor : Color.red)
        }
    }

    private var shortcutsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                shortcutButton(label: "Tout") { setSelection(all: true) }
                shortcutButton(label: "Aucune") { setSelection(all: false) }
                shortcutButton(label: "1 à 13") { setRange(1...13) }
                shortcutButton(label: "14 à 26") { setRange(14...26) }
                shortcutButton(label: "27 à 39") { setRange(27...39) }
                shortcutButton(label: "40 à 52") { setRange(40...52) }
                shortcutButton(label: "Cartes faibles") { selectWeakCards() }
            }
            .padding(.vertical, 2)
        }
    }

    private func shortcutButton(label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.selection()
            action()
            try? modelContext.save()
        } label: {
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(uiColor: .tertiarySystemFill))
                .foregroundStyle(.primary)
                .clipShape(Capsule())
        }
    }

    private var selectionGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(progressItems) { item in
                if let card = item.card {
                    Button {
                        Haptics.shared.selection()
                        item.isKnown.toggle()
                        try? modelContext.save()
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            CardView(card: card, cornerRadius: 6)
                                .opacity(item.isKnown ? 1.0 : 0.28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(item.isKnown ? Color.accentColor : Color.clear, lineWidth: 2)
                                )

                            CardMiniBadge(position: item.position, diameter: 18)
                                .offset(x: 4, y: -4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Bouton Lancer
    private var launchButton: some View {
        Button {
            Haptics.shared.medium()
            isTestActive = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Lancer l'entraînement")
                    .font(.system(.headline, design: .rounded).weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(selectedCount > 0 ? Color.accentColor : Color.gray.opacity(0.4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: selectedCount > 0 ? Color.accentColor.opacity(0.35) : Color.clear, radius: 8, y: 4)
        }
        .disabled(selectedCount == 0)
    }

    // MARK: - Logique des sélections
    private func setSelection(all: Bool) {
        for p in progressItems {
            p.isKnown = all
        }
    }

    private func setRange(_ range: ClosedRange<Int>) {
        for p in progressItems {
            p.isKnown = range.contains(p.position)
        }
    }

    private func selectWeakCards() {
        for p in progressItems {
            p.isKnown = p.isWeak
        }
    }

    // MARK: - Gestion de fin de test
    private func handleTestFinish(results: [TestQuestionResult], duration: Double) {
        isTestActive = false

        if !results.isEmpty {
            let correct = results.filter { $0.isCorrect }.count
            let session = TestSession(
                date: Date(),
                mode: selectedMode.rawValue,
                questionCount: results.count,
                correctCount: correct,
                duration: duration
            )
            modelContext.insert(session)
            try? modelContext.save()

            activeResults = results
            activeDuration = duration
            isResultActive = true
        }
    }

    private func retryWithErrors(_ errorPositions: [Int]) {
        for p in progressItems {
            p.isKnown = errorPositions.contains(p.position)
        }
        try? modelContext.save()
        isResultActive = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isTestActive = true
        }
    }
}
