import SwiftUI
import AudioToolbox
import UIKit

public struct DeviceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var bluetoothManager: BluetoothManager
    @State private var soundEnabled = false
    @State private var vibrateEnabled = false
    @State private var showLocationAlert = false
    @State private var hasReachedSignalThreshold = false

    let device: BluetoothDevice
    let onStop: () -> Void

    public init(device: BluetoothDevice, onStop: @escaping () -> Void) {
        self.device = device
        self.onStop = onStop
        self._bluetoothManager = ObservedObject(wrappedValue: BluetoothManager.shared)
    }

    public var body: some View {
        let currentDevice = liveDevice

        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Move around so that the signal strength increases.")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 320)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                Spacer(minLength: 10)

                RadarView(signalStrength: currentDevice.signalStrength, signalLevel: currentDevice.signalLevel)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 36)

                finderControls
                Spacer(minLength: 10)
                Button {
                    HistoryStore.shared.save(device: liveDevice)
                    onStop()
                    dismiss()
                } label: {
                    Text("I found it!")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
//        .toolbarBackground(.black, for: .navigationBar)
//        .toolbarColorScheme(.dark, for: .navigationBar)
//        .toolbar(.hidden, for: .tabBar)
//        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(device.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Close")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(device.displayName), signal strength \(signalPercentage) percent"))
        .onAppear {
            handleSignalThresholdChange(for: currentDevice.signalStrength)
        }
        .onChange(of: currentDevice.signalStrength) { signalStrength in
            handleSignalThresholdChange(for: signalStrength)
        }
        .alert("Location unavailable", isPresented: $showLocationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The map will open when the signal strength reaches 80%.")
        }
    }

    private var liveDevice: BluetoothDevice {
        bluetoothManager.discoveredDevices.first { $0.id == device.id } ?? device
    }

    private var finderControls: some View {
        HStack(spacing: 18) {
            FinderControl(
                title: "Sound",
                systemImage: "speaker.wave.2.fill",
                isOn: soundEnabled
            ) {
                soundEnabled.toggle()
                if soundEnabled && isSignalReady {
                    playSound()
                }
            }

            FinderControl(
                title: "Vibrate",
                systemImage: "iphone.radiowaves.left.and.right",
                isOn: vibrateEnabled
            ) {
                vibrateEnabled.toggle()
                if vibrateEnabled && isSignalReady {
                    playVibration()
                }
            }

            FinderControl(
                title: "Location",
                systemImage: "location.fill",
                isOn: false
            ) {
                if isSignalReady {
                } else {
                    showLocationAlert = true
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var isSignalReady: Bool {
        liveDevice.signalStrength >= 0.8
    }

    private func handleSignalThresholdChange(for signalStrength: Double) {
        let signalIsReady = signalStrength >= 0.8

        if !signalIsReady {
            hasReachedSignalThreshold = false
            return
        }

        guard !hasReachedSignalThreshold else {
            return
        }

        hasReachedSignalThreshold = true
        if soundEnabled {
            playSound()
        }
        if vibrateEnabled {
            playVibration()
        }
    }

    private func playSound() {
        AudioServicesPlaySystemSound(1057)
    }

    private func playVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private var signalPercentage: Int {
        Int((liveDevice.signalStrength * 100).rounded())
    }
}

private struct FinderControl: View {
    let title: String
    let systemImage: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(isOn ? .blue : .gray)
                    .frame(width: 60, height: 60)
                    .background(isOn ? Color.blue.opacity(0.12) : Color.white.opacity(0.1))
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.gray)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(title), \(isOn ? "On" : "Off")"))
    }
}

//#Preview {
//    DeviceDetailView(device: BluetoothDevice(id: UUID(), name: "AirPods Pro", rssi: -47, smoothedRSSI: -47, signalStrength: 0.86, signalLevel: .veryClose, lastSeen: Date(), category: .audio, trend: .gettingCloser), onStop: {})
//}
