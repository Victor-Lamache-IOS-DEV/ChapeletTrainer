import Foundation

public enum Suit: String, Codable, CaseIterable, Sendable {
    case clubs
    case hearts
    case diamonds
    case spades

    public var code: String {
        switch self {
        case .clubs: return "C"
        case .diamonds: return "D"
        case .hearts: return "H"
        case .spades: return "S"
        }
    }

    public var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .clubs: return "suit.club.fill"
        case .diamonds: return "suit.diamond.fill"
        case .hearts: return "suit.heart.fill"
        case .spades: return "suit.spade.fill"
        }
    }

    public var isRed: Bool {
        self == .hearts || self == .diamonds
    }

    public var nameFR: String {
        switch self {
        case .clubs: return "Trèfle"
        case .diamonds: return "Carreau"
        case .hearts: return "Cœur"
        case .spades: return "Pique"
        }
    }
}

public enum Rank: Int, Codable, CaseIterable, Comparable, Sendable {
    case ace = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case jack
    case queen
    case king

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var code: String {
        switch self {
        case .ace: return "A"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        }
    }

    public var nameFR: String {
        switch self {
        case .ace: return "As"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "Valet"
        case .queen: return "Dame"
        case .king: return "Roi"
        }
    }
}

public struct Card: Hashable, Codable, Identifiable, Sendable {
    public let rank: Rank
    public let suit: Suit

    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    public var id: String { assetName }

    public var assetName: String {
        rank.code + suit.code
    }

    public var shortName: String {
        "\(rank.code)\(suit.symbol)"
    }

    public var displayName: String {
        "\(rank.nameFR) de \(suit.nameFR.lowercased())"
    }
}

public struct MnemonicaDeck {
    /// Les 52 cartes du chapelet Mnemonica de Juan Tamariz, strictement ordonnées de 1 à 52.
    public static let cards: [Card] = [
        Card(rank: .four, suit: .clubs),     // 1: 4♣
        Card(rank: .two, suit: .hearts),     // 2: 2♥
        Card(rank: .seven, suit: .diamonds), // 3: 7♦
        Card(rank: .three, suit: .clubs),    // 4: 3♣
        Card(rank: .four, suit: .hearts),    // 5: 4♥
        Card(rank: .six, suit: .diamonds),   // 6: 6♦
        Card(rank: .ace, suit: .spades),     // 7: A♠
        Card(rank: .five, suit: .hearts),    // 8: 5♥
        Card(rank: .nine, suit: .spades),    // 9: 9♠
        Card(rank: .two, suit: .spades),     // 10: 2♠
        Card(rank: .queen, suit: .hearts),   // 11: Q♥
        Card(rank: .three, suit: .diamonds), // 12: 3♦
        Card(rank: .queen, suit: .clubs),    // 13: Q♣
        Card(rank: .eight, suit: .hearts),   // 14: 8♥
        Card(rank: .six, suit: .spades),     // 15: 6♠
        Card(rank: .five, suit: .spades),    // 16: 5♠
        Card(rank: .nine, suit: .hearts),    // 17: 9♥
        Card(rank: .king, suit: .clubs),     // 18: K♣
        Card(rank: .two, suit: .diamonds),   // 19: 2♦
        Card(rank: .jack, suit: .hearts),    // 20: J♥
        Card(rank: .three, suit: .spades),   // 21: 3♠
        Card(rank: .eight, suit: .spades),   // 22: 8♠
        Card(rank: .six, suit: .hearts),     // 23: 6♥
        Card(rank: .ten, suit: .clubs),      // 24: 10♣
        Card(rank: .five, suit: .diamonds),  // 25: 5♦
        Card(rank: .king, suit: .diamonds),  // 26: K♦
        Card(rank: .two, suit: .clubs),      // 27: 2♣
        Card(rank: .three, suit: .hearts),   // 28: 3♥
        Card(rank: .eight, suit: .diamonds), // 29: 8♦
        Card(rank: .five, suit: .clubs),     // 30: 5♣
        Card(rank: .king, suit: .spades),    // 31: K♠
        Card(rank: .jack, suit: .diamonds),  // 32: J♦
        Card(rank: .eight, suit: .clubs),    // 33: 8♣
        Card(rank: .ten, suit: .spades),     // 34: 10♠
        Card(rank: .king, suit: .hearts),    // 35: K♥
        Card(rank: .jack, suit: .clubs),     // 36: J♣
        Card(rank: .seven, suit: .spades),   // 37: 7♠
        Card(rank: .ten, suit: .hearts),     // 38: 10♥
        Card(rank: .ace, suit: .diamonds),   // 39: A♦
        Card(rank: .four, suit: .spades),    // 40: 4♠
        Card(rank: .seven, suit: .hearts),   // 41: 7♥
        Card(rank: .four, suit: .diamonds),  // 42: 4♦
        Card(rank: .ace, suit: .clubs),      // 43: A♣
        Card(rank: .nine, suit: .clubs),     // 44: 9♣
        Card(rank: .jack, suit: .spades),    // 45: J♠
        Card(rank: .queen, suit: .diamonds), // 46: Q♦
        Card(rank: .seven, suit: .clubs),    // 47: 7♣
        Card(rank: .queen, suit: .spades),   // 48: Q♠
        Card(rank: .ten, suit: .diamonds),   // 49: 10♦
        Card(rank: .six, suit: .clubs),      // 50: 6♣
        Card(rank: .ace, suit: .hearts),     // 51: A♥
        Card(rank: .nine, suit: .diamonds)   // 52: 9♦
    ]

    /// Récupère la carte à la position donnée (1 à 52).
    public static func card(at position: Int) -> Card? {
        guard position >= 1 && position <= cards.count else { return nil }
        return cards[position - 1]
    }

    /// Récupère la position (1 à 52) d'une carte dans le chapelet.
    public static func position(of card: Card) -> Int? {
        guard let index = cards.firstIndex(of: card) else { return nil }
        return index + 1
    }

    /// Les 52 cartes classées par enseigne et par valeur (Pique, Cœur, Carreau, Trèfle),
    /// utilisé pour le mode de test "Position -> Carte" afin de ne pas donner d'indice visuel.
    public static let sortedBySuitAndRank: [Card] = {
        var list: [Card] = []
        let suitOrder: [Suit] = [.spades, .hearts, .diamonds, .clubs]
        for s in suitOrder {
            for r in Rank.allCases {
                list.append(Card(rank: r, suit: s))
            }
        }
        return list
    }()
}
