import SwiftUI
import SwiftData
import UniformTypeIdentifiers

public struct IndicesView: View {
    @Query(sort: \CardProgress.position, order: .forward) private var progressItems: [CardProgress]
    @Environment(\.modelContext) private var modelContext

    @State private var filterWithoutMnemonic: Bool = false
    @State private var searchText: String = ""
    @State private var isImporting: Bool = false
    @State private var importAlertMessage: String?
    @State private var showingImportAlert: Bool = false
    @State private var exportURL: URL?

    public init() {}

    private var filteredItems: [CardProgress] {
        progressItems.filter { item in
            if filterWithoutMnemonic {
                let trimmed = item.mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return false }
            }
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let cardName = item.card?.displayName.lowercased() ?? ""
                let cardShort = item.card?.shortName.lowercased() ?? ""
                let mnemonic = item.mnemonic.lowercased()
                let pos = "\(item.position)"
                if !cardName.contains(query) && !cardShort.contains(query) && !mnemonic.contains(query) && !pos.contains(query) {
                    return false
                }
            }
            return true
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de filtre
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                List {
                    ForEach(filteredItems) { item in
                        IndicesRow(progress: item) {
                            try? modelContext.save()
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Rechercher une carte ou un indice...")
            }
            .navigationTitle("Indices")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Export via ShareLink
                    Button {
                        exportURL = MnemonicSyncService.exportFileURL(from: progressItems)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    // Import
                    Button {
                        isImporting = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(item: $exportURL) { url in
                ShareActivityView(activityItems: [url])
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert("Importation des indices", isPresented: $showingImportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importAlertMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        HStack {
            Toggle(isOn: $filterWithoutMnemonic) {
                HStack(spacing: 6) {
                    Image(systemName: filterWithoutMnemonic ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    Text("Sans indice uniquement")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                }
            }
            .toggleStyle(.button)
            .tint(Color.accentColor)

            Spacer()

            Text("\(filteredItems.count) / 52")
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        do {
            guard let selectedURL = try result.get().first else { return }
            if selectedURL.startAccessingSecurityScopedResource() {
                defer { selectedURL.stopAccessingSecurityScopedResource() }
                let count = MnemonicSyncService.importMnemonics(from: selectedURL, into: progressItems)
                try? modelContext.save()
                importAlertMessage = "\(count) indices ont été importés avec succès."
                showingImportAlert = true
                Haptics.shared.success()
            }
        } catch {
            importAlertMessage = "Erreur lors de l'import : \(error.localizedDescription)"
            showingImportAlert = true
            Haptics.shared.error()
        }
    }
}

private struct IndicesRow: View {
    @Bindable var progress: CardProgress
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Miniature carte
            if let card = progress.card {
                CardView(card: card, cornerRadius: 5)
                    .frame(width: 36, height: 50)
            }

            // Numéro
            Text("\(progress.position)")
                .font(.system(.headline, design: .monospaced).weight(.bold))
                .frame(width: 28, alignment: .leading)
                .foregroundStyle(.secondary)

            // Champ texte
            TextField("Phrase mnémotechnique...", text: $progress.mnemonic)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .rounded))
                .onChange(of: progress.mnemonic) { _, _ in
                    onSave()
                }

            if !progress.mnemonic.isEmpty {
                Button {
                    progress.mnemonic = ""
                    onSave()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

// Helper pour rendre URL Identifiable pour la feuille de partage
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

public struct ShareActivityView: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
