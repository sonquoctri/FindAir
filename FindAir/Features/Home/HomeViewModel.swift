import Foundation
import SwiftUI
import Combine

@MainActor
public final class HomeViewModel: ObservableObject {
    public let bluetoothManager: BluetoothManager

    @Published public var devices: [BluetoothDevice] = []
    @Published public var state: BluetoothManagerState = .unsupported
    @Published public var status: String = "Bluetooth access is required to discover nearby devices."
    @Published public var isScanning = false

    private var cancellables = Set<AnyCancellable>()

    public init(bluetoothManager: BluetoothManager? = nil) {
        self.bluetoothManager = bluetoothManager ?? BluetoothManager.shared

        self.devices = self.bluetoothManager.discoveredDevices
        self.state = self.bluetoothManager.state
        self.status = self.bluetoothManager.statusMessage
        self.isScanning = self.bluetoothManager.isScanning

        self.bluetoothManager.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.devices = devices
            }
            .store(in: &cancellables)

        self.bluetoothManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)

        self.bluetoothManager.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.status = status
            }
            .store(in: &cancellables)

        self.bluetoothManager.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isScanning in
                self?.isScanning = isScanning
            }
            .store(in: &cancellables)
    }

    public func toggleScan() {
        if bluetoothManager.isScanning {
            bluetoothManager.stopScan()
        } else {
            bluetoothManager.startScan()
        }
    }
}
