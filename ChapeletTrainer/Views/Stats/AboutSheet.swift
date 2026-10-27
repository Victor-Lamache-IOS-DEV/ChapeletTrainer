import SwiftUI

public struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête
                    VStack(spacing: 12) {
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)

                        Text("Chapelet Trainer")
                            .font(.system(.title, design: .rounded).weight(.heavy))

                        Text("Version 1.0 (Build 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    // Hommage Mnemonica
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Le Chapelet Mnemonica", systemImage: "sparkles")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)

                        Text("Conçu par le maître espagnol Juan Tamariz, le chapelet Mnemonica est l'un des ordres mémorisés les plus renommés et puissants de la cartomagie contemporaine.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )

                    // Licence des cartes
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Graphismes des Cartes", systemImage: "photo.stack")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)

                        Text("Les images des 52 cartes proviennent du projet open-source Vector-Playing-Cards par notpeter, basé sur les illustrations vectorielles originales créées par Byron Knoll.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)

                        Text("Licence : Domaine Public / WTFPL (Do What The Fuck You Want To Public License).")
                            .font(.system(.caption, design: .monospaced).weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )

                    // Philosophie
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Philosophie & Confidentialité", systemImage: "lock.shield.fill")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)

                        Text("Cette application fonctionne à 100% hors ligne, sans compte, sans publicité, et sans aucun traceur. Toutes vos données sont enregistrées en local sur votre appareil.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
