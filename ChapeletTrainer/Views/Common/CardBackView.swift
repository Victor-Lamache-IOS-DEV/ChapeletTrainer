import SwiftUI

public struct CardBackView: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let cornerRadius = w * 0.08
            let borderWidth = max(2.0, w * 0.035)

            ZStack {
                // Fond extérieur blanc (bordure carte)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)

                // Panneau intérieur bleu nuit royal
                RoundedRectangle(cornerRadius: cornerRadius * 0.8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.16, blue: 0.38),
                                Color(red: 0.04, green: 0.08, blue: 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(borderWidth)
                    .overlay(
                        // Motif géométrique fin
                        RoundedRectangle(cornerRadius: cornerRadius * 0.8, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                            .padding(borderWidth + 3)
                    )
                    .overlay(
                        // Losange / motif central
                        ZStack {
                            Rectangle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.2)
                                .rotationEffect(.degrees(45))
                                .frame(width: w * 0.35, height: w * 0.35)

                            Image(systemName: "sparkles")
                                .font(.system(size: w * 0.2, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                    )
            }
            .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 2)
        }
        .aspectRatio(2.5 / 3.5, contentMode: .fit)
    }
}
