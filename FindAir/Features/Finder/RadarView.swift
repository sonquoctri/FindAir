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
                .fill(Color.white.opacity(0.1))
                .frame(width: maximumRadius, height: maximumRadius)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.24), lineWidth: 0)
                }
                .position(center)

            Circle()
                .fill(signalLevelColor.opacity(0.4))
                .frame(width: maximumRadius, height: maximumRadius)
                .scaleEffect(pulseScale, anchor: .center)
                .opacity(pulseOpacity)
                .animation(
                    .easeOut(duration: 1.2)
                        .repeatForever(autoreverses: false),
                    value: animate
                )
                .position(center)

            Circle()
                .fill(signalLevelColor.opacity(0.35))
                .frame(width: strengthRadius, height: strengthRadius)
                .overlay {
                    Circle()
                        .stroke(signalLevelColor.opacity(0.55), lineWidth: 0)
                }
                    .position(center)

            Circle()
                .fill(Color.blue)
                .frame(width: 112, height: 112)
                .overlay {
                    Circle()
                        .stroke(Color.white, lineWidth: 5)
                }
                .overlay {
                    Text("\(signalPercentage)%")
                        .font(.system(size: 38, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.accentColor, radius: 16)
                .position(center)
        }
            .frame(width: canvasSize, height: canvasSize)
        .onAppear {
            animate = true
        }
        .accessibilityHidden(true)
    }

    private var signalPercentage: Int {
        Int((signalStrength * 100).rounded())
    }

    private var strengthRadius: CGFloat {
        let normalizedStrength = min(max(signalStrength, 0), 1)
        return minimumRadius + normalizedStrength * (maximumRadius - minimumRadius)
    }

    private var minimumRadius: CGFloat {
        150
    }

    private var maximumRadius: CGFloat {
        360
    }

    private var canvasSize: CGFloat {
        maximumRadius
    }

    private var center: CGPoint {
        CGPoint(x: canvasSize / 2, y: canvasSize / 2)
    }

    private var pulseScale: CGFloat {
        animate ? 1 : strengthRadius / maximumRadius
    }

    private var pulseOpacity: Double {
        animate ? 0 : 0.65
    }

    private var signalLevelColor: Color {
        switch signalLevel {
        case .veryFar:
            return .blue
        case .far:
            return .blue
        case .nearby:
            return .blue
        case .close:
            return .blue
        case .veryClose:
            return .blue
        }
    }
}

//#Preview {
//    RadarView(signalStrength: 0.9, signalLevel: .veryClose)
//}
