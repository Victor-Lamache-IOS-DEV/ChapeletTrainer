import UIKit

@MainActor
public final class Haptics {
    public static let shared = Haptics()
    private init() {}

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notifyGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    public func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notifyGenerator.prepare()
    }

    public func light() {
        lightGenerator.impactOccurred()
    }

    public func medium() {
        mediumGenerator.impactOccurred()
    }

    public func heavy() {
        heavyGenerator.impactOccurred()
    }

    public func success() {
        notifyGenerator.notificationOccurred(.success)
    }

    public func error() {
        notifyGenerator.notificationOccurred(.error)
    }

    public func warning() {
        notifyGenerator.notificationOccurred(.warning)
    }

    public func selection() {
        selectionGenerator.selectionChanged()
    }
}
