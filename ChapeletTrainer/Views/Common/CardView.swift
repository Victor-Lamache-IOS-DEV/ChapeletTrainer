import SwiftUI

public struct CardView: View {
    public let card: Card
    public var cornerRadius: CGFloat = 8

    // Cache statique des 52 noms d'assets pour éviter tout appel disque ou catalogue répété dans body
    private static let knownAssets: Set<String> = Set(MnemonicaDeck.cards.map(\.assetName))

    public init(card: Card, cornerRadius: CGFloat = 8) {
        self.card = card
        self.cornerRadius = cornerRadius
    }

    private var hasAssetImage: Bool {
        Self.knownAssets.contains(card.assetName)
    }

    public var body: some View {
        ZStack {
            // Fond blanc avec ombre optimisée (rendu GPU matériel direct sur CGPath continu)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.18), radius: 2.5, x: 0, y: 1.5)

            if hasAssetImage {
                Image(card.assetName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                fallbackCardView
            }
        }
        .aspectRatio(2.5 / 3.5, contentMode: .fit)
    }

    /// Plan B : Rendu SwiftUI natif vectoriel élégant en cas d'absence d'image
    @ViewBuilder
    private var fallbackCardView: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let cornerFont = Font.system(size: max(9, w * 0.18), weight: .bold, design: .rounded)
            let centerFont = Font.system(size: max(14, w * 0.38))
            let color = card.suit.isRed ? Color.red : Color.black

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)

                // Coin supérieur gauche
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(spacing: 0) {
                            Text(card.rank.code)
                                .font(cornerFont)
                                .foregroundStyle(color)
                            Text(card.suit.symbol)
                                .font(cornerFont)
                                .foregroundStyle(color)
                        }
                        .padding([.top, .leading], max(3, w * 0.06))
                        Spacer()
                    }
                    Spacer()
                }

                // Symbole central
                Image(systemName: card.suit.sfSymbol)
                    .font(centerFont)
                    .foregroundStyle(color)

                // Coin inférieur droit (inversé)
                VStack(alignment: .trailing, spacing: 0) {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            Text(card.rank.code)
                                .font(cornerFont)
                                .foregroundStyle(color)
                            Text(card.suit.symbol)
                                .font(cornerFont)
                                .foregroundStyle(color)
                        }
                        .rotationEffect(.degrees(180))
                        .padding([.bottom, .trailing], max(3, w * 0.06))
                    }
                }
            }
        }
    }
}
