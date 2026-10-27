import Foundation

public enum TestMode: String, CaseIterable, Identifiable, Sendable {
    case cardToPosition = "cardToPosition"
    case positionToCard = "positionToCard"
    case mixed = "mixed"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .cardToPosition:
            return "Carte → Position"
        case .positionToCard:
            return "Position → Carte"
        case .mixed:
            return "Mixte"
        }
    }

    public var subtitle: String {
        switch self {
        case .cardToPosition:
            return "Une carte s'affiche, tapez son numéro"
        case .positionToCard:
            return "Un numéro s'affiche, choisissez la carte"
        case .mixed:
            return "Alternance des deux modes"
        }
    }

    public var systemImage: String {
        switch self {
        case .cardToPosition:
            return "number.circle.fill"
        case .positionToCard:
            return "suit.spade.fill"
        case .mixed:
            return "arrow.triangle.swap"
        }
    }
}

public enum QuestionCountOption: Hashable, Identifiable, Sendable {
    case fixed(Int)
    case all
    case endless

    public var id: String {
        switch self {
        case .fixed(let count): return "fixed_\(count)"
        case .all: return "all"
        case .endless: return "endless"
        }
    }

    public var title: String {
        switch self {
        case .fixed(let count): return "\(count)"
        case .all: return "Toutes"
        case .endless: return "Sans fin"
        }
    }

    public static let defaults: [QuestionCountOption] = [
        .fixed(10),
        .fixed(20),
        .all,
        .endless
    ]
}
