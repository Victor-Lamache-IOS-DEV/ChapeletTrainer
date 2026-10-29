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

    // Sélection de carte (Position -> Carte)
    @State private var cardPickerMode: CardPickerMode = .columns
    @State private var selectedRankForGuess: Rank? = nil

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
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                }

                if showTimer {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text(formattedTime(elapsedSeconds))
                                .font(.system(.caption, design: .monospaced).weight(.bold))
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
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .foregroundStyle(.green)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text("\(sessionResults.filter { !$0.isCorrect }.count)")
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
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
        guard !showingFeedback else { return }
        guard typedNumber.count < 2 else { return }

        typedNumber.append(digit)

        if let guess = Int(typedNumber) {
            if guess == currentPosition {
                // Dès que l'utilisateur tape le bon numéro, validation automatique immédiate !
                validatePositionGuess()
            } else if typedNumber.count == 2 {
                // Dès que 2 chiffres sont saisis (maximum possible pour 1..52) -> validation automatique
                validatePositionGuess()
            } else if guess >= 6 {
                // Dans un jeu de 52 cartes, aucun numéro valide ne commence par 6, 7, 8 ou 9.
                // Donc s'il tape 6..9, c'est obligatoirement sa réponse finale à 1 chiffre.
                validatePositionGuess()
            }
        }
    }

    private func validatePositionGuess() {
        guard let guess = Int(typedNumber) else { return }
        let isCorrect = (guess == currentPosition)
        processAnswer(isCorrect: isCorrect, userGuess: "\(guess)")
    }

    // MARK: - Mode Position -> Carte
    private let cardPickerSuits: [(suit: Suit, label: String)] = [
        (.spades, "Pique ♠"),
        (.hearts, "Cœur ♥"),
        (.clubs, "Trèfle ♣"),
        (.diamonds, "Carreau ♦")
    ]

    private var positionToCardView: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Quelle carte est à la position :")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)

                Text("#\(currentPosition)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }

            // Sélecteur de mode de présentation
            Picker("Présentation", selection: $cardPickerMode) {
                Text("4 Colonnes (52 directes)").tag(CardPickerMode.columns)
                Text("Clavier 2 temps").tag(CardPickerMode.keypad)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            if cardPickerMode == .columns {
                fourColumnsCardPicker
                    .padding(.horizontal, 8)
            } else {
                twoStepKeypadView
            }
        }
    }

    // Présentation 4 colonnes par famille : 52 cartes directes sans défilement horizontal
    private var fourColumnsCardPicker: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(cardPickerSuits, id: \.suit) { s in
                VStack(spacing: 3) {
                    Text(s.label)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(s.suit.isRed ? Color.red : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(s.suit.isRed ? Color.red.opacity(0.12) : Color.primary.opacity(0.08))
                        )

                    ForEach(Rank.allCases, id: \.self) { rank in
                        let card = Card(rank: rank, suit: s.suit)
                        cardPickerCell(card: card, suit: s.suit)
                    }
                }
            }
        }
    }

    private func cardPickerCell(card: Card, suit: Suit) -> some View {
        Button {
            Haptics.shared.selection()
            selectCardGuess(card)
        } label: {
            HStack(spacing: 3) {
                CardView(card: card, cornerRadius: 3)
                    .frame(width: 20, height: 28)

                Text(card.rank.code)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(suit.isRed ? Color.red : Color.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(suit.isRed ? Color.red.opacity(0.18) : Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(showingFeedback)
    }

    // Clavier rapide en 2 étapes (Optionnel pour de très grands boutons)
    private var twoStepKeypadView: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedRankForGuess == nil ? "1. Choisissez la valeur :" : "Valeur : \(selectedRankForGuess?.nameFR ?? "")")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                    ForEach(Rank.allCases, id: \.self) { rank in
                        Button {
                            Haptics.shared.selection()
                            selectedRankForGuess = rank
                        } label: {
                            Text(rank.code)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selectedRankForGuess == rank ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                                .foregroundStyle(selectedRankForGuess == rank ? Color.white : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(showingFeedback)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("2. Choisissez la couleur :")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(cardPickerSuits, id: \.suit) { s in
                        Button {
                            guard let rank = selectedRankForGuess else {
                                Haptics.shared.warning()
                                return
                            }
                            let card = Card(rank: rank, suit: s.suit)
                            selectCardGuess(card)
                            selectedRankForGuess = nil
                        } label: {
                            VStack(spacing: 2) {
                                Text(s.suit.symbol)
                                    .font(.system(size: 26, weight: .bold))
                                Text(s.suit.nameFR)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .foregroundStyle(s.suit.isRed ? Color.red : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(s.suit.isRed ? Color.red.opacity(0.2) : Color.primary.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(showingFeedback || selectedRankForGuess == nil)
                        .opacity(selectedRankForGuess == nil ? 0.45 : 1.0)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
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
        selectedRankForGuess = nil
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
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(lastAnswerCorrect ? Color.green : Color.red)

                    if !lastAnswerCorrect, let card = feedbackCorrectCard {
                        Text("La bonne réponse : \(card.displayName) (#\(feedbackCorrectPosition))")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                Spacer()

                Button {
                    advanceToNextQuestion()
                } label: {
                    Text("Continuer")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
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
                        .font(.system(.footnote, design: .rounded).weight(.medium))
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

private enum CardPickerMode: String, CaseIterable, Identifiable {
    case columns = "Colonnes"
    case keypad = "Clavier"

    var id: String { rawValue }
}

