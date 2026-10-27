import SwiftUI
import SwiftData

public enum RevisionMode: String, CaseIterable, Identifiable {
    case showAll = "showAll"
    case hideNumbers = "hideNumbers"
    case hideCards = "hideCards"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .showAll: return "Tout afficher"
        case .hideNumbers: return "Masquer les numéros"
        case .hideCards: return "Masquer les cartes"
        }
    }

    public var iconName: String {
        switch self {
        case .showAll: return "eye"
        case .hideNumbers: return "number.circle"
        case .hideCards: return "rectangle.portrait.slash"
        }
    }
}

public struct ChapeletView: View {
    @Query(sort: \CardProgress.position, order: .forward) private var progressItems: [CardProgress]
    @Environment(\.modelContext) private var modelContext

    @State private var revisionMode: RevisionMode = .showAll
    @State private var revealedPositions: Set<Int> = []
    @State private var selectedCardProgress: CardProgress?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Fond noir pur permanent
                Color.black.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(1...52, id: \.self) { position in
                            if let card = MnemonicaDeck.card(at: position) {
                                let progress = progressForPosition(position)
                                cardCell(position: position, card: card, progress: progress)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Chapelet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Mode révision", selection: $revisionMode) {
                            ForEach(RevisionMode.allCases) { mode in
                                Label(mode.title, systemImage: mode.iconName)
                                    .tag(mode)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: revisionMode.iconName)
                            Text(revisionButtonLabel)
                                .font(.system(.subheadline, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color(white: 0.2))
                        )
                    }
                }
            }
            .sheet(item: $selectedCardProgress) { progress in
                CardDetailSheet(progress: progress)
            }
            .onChange(of: revisionMode) { _, _ in
                revealedPositions.removeAll()
            }
        }
    }

    private var revisionButtonLabel: String {
        switch revisionMode {
        case .showAll: return "Révision"
        case .hideNumbers: return "Sans N°"
        case .hideCards: return "Dos"
        }
    }

    private func progressForPosition(_ pos: Int) -> CardProgress? {
        progressItems.first { $0.position == pos }
    }

    @ViewBuilder
    private func cardCell(position: Int, card: Card, progress: CardProgress?) -> some View {
        let isRevealed = revealedPositions.contains(position)
        let showFace = (revisionMode != .hideCards) || isRevealed
        let showNumber = (revisionMode != .hideNumbers) || isRevealed

        Button {
            handleCardTap(position: position, progress: progress)
        } label: {
            ZStack(alignment: .topTrailing) {
                // Corps de la carte : face ou dos
                if showFace {
                    CardView(card: card, cornerRadius: 8)
                } else {
                    CardBackView()
                }

                // Badge du numéro centré sur le coin supérieur droit et à cheval dessus
                if showNumber {
                    CardMiniBadge(position: position, diameter: 22)
                        .offset(x: 6, y: -6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let p = progress {
                Button {
                    selectedCardProgress = p
                } label: {
                    Label("Voir la fiche", systemImage: "info.circle")
                }
            }
            if revisionMode != .showAll {
                Button {
                    toggleReveal(position: position)
                } label: {
                    Label(isRevealed ? "Masquer" : "Révéler", systemImage: isRevealed ? "eye.slash" : "eye")
                }
            }
        }
    }

    private func handleCardTap(position: Int, progress: CardProgress?) {
        if revisionMode == .showAll {
            Haptics.shared.light()
            selectedCardProgress = progress
        } else {
            // En mode révision, toucher révèle l'élément masqué
            Haptics.shared.selection()
            toggleReveal(position: position)
        }
    }

    private func toggleReveal(position: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if revealedPositions.contains(position) {
                revealedPositions.remove(position)
            } else {
                revealedPositions.insert(position)
            }
        }
    }
}
