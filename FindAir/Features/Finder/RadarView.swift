import SwiftUI

public struct RadarView: View {
    let signalStrength: Double
    let signalLevel: SignalLevel
    @State private var animate = false

    public init(signalStrength: Double, signalLevel: SignalLevel) {
        self.signalStrength = signalStrength
        self.signalLevel = signalLevel
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                .frame(width: 260, height: 260)
            Circle()
                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                .frame(width: 190, height: 190)
            Circle()
                .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                .frame(width: 120, height: 120)

            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.accentColor.opacity(0.4), lineWidth: 1.1)
                    .frame(width: CGFloat(60 + index * 55) * (0.8 + signalStrength * 0.6), height: CGFloat(60 + index * 55) * (0.8 + signalStrength * 0.6))
                    .scaleEffect(animate ? 1.0 : 0.88)
                    .opacity(animate ? 0.4 : 0.8)
                    .animation(.easeInOut(duration: 2.2 + Double(index) * 0.6).repeatForever(autoreverses: true), value: animate)
            }

            Circle()
                .fill(Color.accentColor)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))

            Circle()
                .fill(signalLevelColor)
                .frame(width: 28 + signalStrength * 24, height: 28 + signalStrength * 24)
                .offset(x: 0, y: -80 + signalStrength * 45)
                .shadow(color: signalLevelColor.opacity(0.45), radius: 18)
        }
        .frame(width: 280, height: 280)
        .onAppear {
            animate = true
        }
        .accessibilityHidden(true)
    }

    private var signalLevelColor: Color {
        switch signalLevel {
        case .veryFar:
            return .gray
        case .far:
            return .blue
        case .nearby:
            return .teal
        case .close:
            return .orange
        case .veryClose:
            return .green
        }
    }
}

#Preview {
    RadarView(signalStrength: 0.9, signalLevel: .veryClose)
}
