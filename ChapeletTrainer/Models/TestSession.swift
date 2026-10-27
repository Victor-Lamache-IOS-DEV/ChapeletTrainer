import Foundation
import SwiftData

@Model
public final class TestSession {
    public var date: Date
    public var mode: String             // "cardToPosition" / "positionToCard" / "mixed"
    public var questionCount: Int
    public var correctCount: Int
    public var duration: Double         // En secondes, à titre purement indicatif

    public init(
        date: Date = Date(),
        mode: String,
        questionCount: Int,
        correctCount: Int,
        duration: Double
    ) {
        self.date = date
        self.mode = mode
        self.questionCount = questionCount
        self.correctCount = correctCount
        self.duration = duration
    }

    public var successRate: Double {
        guard questionCount > 0 else { return 0.0 }
        return Double(correctCount) / Double(questionCount)
    }

    public var wrongCount: Int {
        max(0, questionCount - correctCount)
    }

    public var formattedDuration: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: "%d min %02d s", minutes, seconds)
        } else {
            return String(format: "%d s", seconds)
        }
    }

    public var modeDisplayName: String {
        switch mode {
        case "cardToPosition":
            return "Carte → Position"
        case "positionToCard":
            return "Position → Carte"
        case "mixed":
            return "Mixte"
        default:
            return mode
        }
    }
}
