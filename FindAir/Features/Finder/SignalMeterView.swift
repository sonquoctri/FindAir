import SwiftUI

public struct SignalMeterView: View {
    let value: Double
    var height: CGFloat = 12

    public init(value: Double, height: CGFloat = 12) {
        self.value = value
        self.height = height
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, geometry.size.width * value))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                .blue,
                .teal,
                .green,
                .orange,
                .red
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    SignalMeterView(value: 0.8)
        .padding()
}
