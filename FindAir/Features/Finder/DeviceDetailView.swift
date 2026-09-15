import SwiftUI

public struct DeviceDetailView: View {
    let device: BluetoothDevice
    let onStop: () -> Void

    public init(device: BluetoothDevice, onStop: @escaping () -> Void) {
        self.device = device
        self.onStop = onStop
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(device.displayName)
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.top)

                RadarView(signalStrength: device.signalStrength, signalLevel: device.signalLevel)

                VStack(spacing: 8) {
                    Text(device.signalLevel.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(device.trend.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("Signal trend: \(device.trend.title)"))
                }

                VStack(alignment: .leading, spacing: 10) {
                    SignalMeterView(value: device.signalStrength, height: 14)
                    HStack {
                        Text("RSSI")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(device.rssi) dBm")
                            .foregroundStyle(.primary)
                    }
                    HStack {
                        Text("Last seen")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(device.lastSeenText)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("Move around to improve the signal and locate your device. Bluetooth signal strength is only a proximity guide, not an exact distance measurement.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: onStop) {
                    Label("Stop", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(device.displayName), \(device.signalLevel.title), \(device.trend.title)"))
    }
}

#Preview {
    DeviceDetailView(device: BluetoothDevice(id: UUID(), name: "AirPods Pro", rssi: -47, smoothedRSSI: -47, signalStrength: 0.86, signalLevel: .veryClose, lastSeen: Date(), category: .audio, trend: .gettingCloser), onStop: {})
}
