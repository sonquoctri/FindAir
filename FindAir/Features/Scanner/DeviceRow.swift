import SwiftUI

public struct DeviceRow: View {
    let device: BluetoothDevice
    let isSelected: Bool

    public init(device: BluetoothDevice, isSelected: Bool = false) {
        self.device = device
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(device.signalLevelColor)
                    .frame(width: 42, height: 42)
                Image(systemName: device.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(device.signalLevel.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                SignalMeterView(value: device.signalStrength, height: 8)
                    .frame(width: 110)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if device.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Text(device.lastSeenText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(device.displayName), \(device.signalLevel.title)"))
        .accessibilityValue(Text("Signal strength \(device.signalStrength, specifier: "%.0f") percent"))
    }
}

private extension BluetoothDevice {
    var signalLevelColor: Color {
        switch signalLevel {
        case .veryFar:
            return .gray
        case .far:
            return .blue.opacity(0.7)
        case .nearby:
            return .green.opacity(0.7)
        case .close:
            return .orange.opacity(0.8)
        case .veryClose:
            return .green
        }
    }

    var symbolName: String {
        switch category {
        case .audio:
            return "speaker.wave.2.fill"
        case .wearables:
            return "applewatch.watchface"
        case .phonesTablets:
            return "iphone.gen2"
        case .all, .other:
            return "dot.radiowaves.left.and.right"
        }
    }
}

#Preview {
    DeviceRow(device: BluetoothDevice(id: UUID(), name: "AirPods Pro", rssi: -47, smoothedRSSI: -47, signalStrength: 0.9, signalLevel: .veryClose, lastSeen: Date(), category: .audio, trend: .gettingCloser))
        .padding()
}
