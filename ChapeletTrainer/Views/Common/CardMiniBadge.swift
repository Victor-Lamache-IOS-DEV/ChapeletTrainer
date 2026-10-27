import SwiftUI

public struct CardMiniBadge: View {
    public let position: Int
    public var diameter: CGFloat = 22

    public init(position: Int, diameter: CGFloat = 22) {
        self.position = position
        self.diameter = diameter
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )

            Text("\(position)")
                .font(.system(size: diameter * 0.52, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}
