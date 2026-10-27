import SwiftUI
import SwiftData

public struct TestQuestionResult: Identifiable {
    public let id = UUID()
    public let position: Int
    public let card: Card
    public let userGuess: String
    public let isCorrect: Bool
    public let mnemonic: String
}

public struct TestActiveView: View {
    public let selectedPositions: [Int]
    public let configMode: TestMode
    public let questionCountOption: QuestionCountOption
    public let showTimer: Bool
    public let onFinish: ([TestQuestionResult], Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var progressItems: [CardProgress]

    // État de session
    @State private var currentQuestionIndex: Int = 0
    @State private var currentPosition: Int = 1
    @State private var currentQuestionMode: TestMode = .cardToPosition
    @State private var sessionResults: [TestQuestionResult] = []

    // Saisie utilisateur (Carte -> Position)
    @State private var typedNumber: String = ""

    // État de feedback immédiat
    @State private var showingFeedback: Bool = false
    @State private var lastAnswerCorrect: Bool = false
    @State private var feedbackCorrectCard: Card?
    @State private var feedbackCorrectPosition: Int = 0
    @State private var feedbackMnemonic: String = ""

    // Chronomètre indicatif
    @State private var elapsedSeconds: Double = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(
        selectedPositions: [Int],
        configMode: TestMode,
        questionCountOption: QuestionCountOption,
        showTimer: Bool,
        onFinish: @escaping ([TestQuestionResult], Double) -> Void
    ) {
        self.selectedPositions = selectedPositions
        self.configMode = configMode
        self.questionCountOption = questionCountOption
        self.showTimer = showTimer
        self.onFinish = onFinish
    }

    private var totalQuestions: Int? {
        switch questionCountOption {
        case .fixed(let count): return count
        case .all: return selectedPositions.count
        case .endless: return nil
        }
    }

    private var progressMap: [Int: CardProgress] {
        Dictionary(uniqueKeysWithValues: progressItems.map { ($0.position, $0) })
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header : Barre de statut & Chronomètre indicatif
                headerView
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground))

                // Contenu interactif selon le mode
                ScrollView {
                    VStack(spacing: 16) {
                        if currentQuestionMode == .cardToPosition {
                            cardToPositionView
                        } else {
                            positionToCardView
                        }
                    }
                    .padding(.vertical, 12)
                }

                // Feedback immédiat en bas si répondu
                if showingFeedback {
                    feedbackBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abandonner") {
                        endSession()
                    }
                    .foregroundStyle(.red)
                }

                ToolbarItem(placement: .principal) {
                    Text(progressTitle)
                        .font(.system(.subheadline, weight: .bold, design: .rounded))
                }

                if showTimer {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text(formattedTime(elapsedSeconds))
                                .font(.system(.caption, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                startNextQuestion()
            }
            .onReceive(timer) { _ in
                elapsedSeconds += 1
            }
        }
    }

    private var progressTitle: String {
        if let total = totalQuestions {
            return "Question \(currentQuestionIndex + 1) / \(total)"
        } else {
            return "Question \(currentQuestionIndex + 1)"
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("\(sessionResults.filter { $0.isCorrect }.count)")
                    .font(.system(.subheadline, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text("\(sessionResults.filter { !$0.isCorrect }.count)")
                    .font(.system(.subheadline, weight: .bold, design: .monospaced))
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Mode Carte -> Position
    private var cardToPositionView: some View {
        VStack(spacing: 16) {
            if let card = MnemonicaDeck.card(at: currentPosition) {
                CardView(card: card, cornerRadius: 14)
                    .frame(height: 200)
                    .padding(.top, 4)
            }

            // Affichage du numéro saisi
            HStack(spacing: 8) {
                Text("Position :")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(typedNumber.isEmpty ? "—" : typedNumber)
                    .font(.system(size: 36, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.accentColor)
                    .frame(minWidth: 70)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .tertiarySystemFill))
                    )
            }

            // Pavé numérique tactile personnalisé
            customNumpad
                .padding(.horizontal, 24)
        }
    }

    private var customNumpad: some View {
        VStack(spacing: 10) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { num in
                        numpadButton(label: "\(num)") {
                            appendDigit("\(num)")
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                // Bouton Effacer
                Button {
                    Haptics.shared.light()
                    if !typedNumber.isEmpty {
                        typedNumber.removeLast()
                    }
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(uiColor: .secondarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(showingFeedback)

                // 0
                numpadButton(label: "0") {
                    appendDigit("0")
                }

                // Bouton Valider
                Button {
                    validatePositionGuess()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(typedNumber.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(typedNumber.isEmpty || showingFeedback)
            }
        }
    }

    private func numpadButton(label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.light()
            action()
        } label: {
            Text(label)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color(uiColor: .secondarySystemFill))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(showingFeedback)
    }

    private func appendDigit(_ digit: String) {
        if typedNumber.count < 2 {
            typedNumber.append(digit)
        }
    }

    private func validatePositionGuess() {
        guard let guess = Int(typedNumber) else { return }
        let isCorrect = (guess == currentPosition)
        processAnswer(isCorrect: isCorrect, userGuess: "\(guess)")
    }

    // MARK: - Mode Position -> Carte
    private var positionToCardView: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Quelle carte est à la position :")
                    .font(.system(.subheadline, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("#\(currentPosition)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }

            // Grille des 52 cartes classées par couleur et par valeur
            VStack(alignment: .leading, spacing: 8) {
                let suits: [(suit: Suit, label: String)] = [
                    (.spades, "Pique ♠"),
                    (.hearts, "Cœur ♥"),
                    (.diamonds, "Carreau ♦"),
                    (.clubs, "Trèfle ♣")
                ]

                ForEach(suits, id: \.suit) { s in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(s.suit.isRed ? Color.red : Color.primary)
                            .padding(.leading, 12)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Rank.allCases, id: \.self) { rank in
                                    let card = Card(rank: rank, suit: s.suit)
                                    Button {
                                        selectCardGuess(card)
                                    } label: {
                                        CardView(card: card, cornerRadius: 4)
                                            .frame(width: 44, height: 62)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(showingFeedback)
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                }
            }
        }
    }

    private func selectCardGuess(_ chosenCard: Card) {
        let correctCard = MnemonicaDeck.card(at: currentPosition)
        let isCorrect = (chosenCard == correctCard)
        processAnswer(isCorrect: isCorrect, userGuess: chosenCard.shortName)
    }

    // MARK: - Traitement de la réponse
    private func processAnswer(isCorrect: Bool, userGuess: String) {
        guard let card = MnemonicaDeck.card(at: currentPosition) else { return }

        // Mettre à jour CardProgress
        let progress = progressMap[currentPosition]
        progress?.recordAnswer(isCorrect: isCorrect)
        try? modelContext.save()

        feedbackCorrectCard = card
        feedbackCorrectPosition = currentPosition
        feedbackMnemonic = progress?.mnemonic ?? ""
        lastAnswerCorrect = isCorrect
        showingFeedback = true

        let result = TestQuestionResult(
            position: currentPosition,
            card: card,
            userGuess: userGuess,
            isCorrect: isCorrect,
            mnemonic: progress?.mnemonic ?? ""
        )
        sessionResults.append(result)

        if isCorrect {
            Haptics.shared.success()
            // Passage automatique après court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if showingFeedback {
                    advanceToNextQuestion()
                }
            }
        } else {
            Haptics.shared.error()
            // Sur erreur, on laisse l'utilisateur lire l'indice et appuyer sur "Continuer"
        }
    }

    private func advanceToNextQuestion() {
        showingFeedback = false
        typedNumber = ""
        currentQuestionIndex += 1

        if let total = totalQuestions, currentQuestionIndex >= total {
            endSession()
        } else {
            startNextQuestion()
        }
    }

    private func startNextQuestion() {
        guard let nextPos = DeckStore.pickNextQuestion(
            from: selectedPositions,
            progressMap: progressMap,
            lastPickedPosition: currentPosition
        ) else {
            endSession()
            return
        }

        currentPosition = nextPos

        switch configMode {
        case .cardToPosition:
            currentQuestionMode = .cardToPosition
        case .positionToCard:
            currentQuestionMode = .positionToCard
        case .mixed:
            currentQuestionMode = Bool.random() ? .cardToPosition : .positionToCard
        }
    }

    private func endSession() {
        timer.upstream.connect().cancel()
        onFinish(sessionResults, elapsedSeconds)
    }

    // MARK: - Bannière de Feedback
    @ViewBuilder
    private var feedbackBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(lastAnswerCorrect ? Color.green : Color.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(lastAnswerCorrect ? "Exact !" : "Erreur")
                        .font(.system(.headline, weight: .bold, design: .rounded))
                        .foregroundStyle(lastAnswerCorrect ? Color.green : Color.red)

                    if !lastAnswerCorrect, let card = feedbackCorrectCard {
                        Text("La bonne réponse : \(card.displayName) (#\(feedbackCorrectPosition))")
                            .font(.system(.subheadline, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
                Spacer()

                Button {
                    advanceToNextQuestion()
                } label: {
                    Text("Continuer")
                        .font(.system(.subheadline, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(lastAnswerCorrect ? Color.green : Color.red)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            if !lastAnswerCorrect && !feedbackMnemonic.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Indice : \(feedbackMnemonic)")
                        .font(.system(.footnote, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(8)
                .background(Color(uiColor: .tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: -3)
        )
    }

    private func formattedTime(_ totalSeconds: Double) -> String {
        let sec = Int(totalSeconds)
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}
