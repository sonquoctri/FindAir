import Foundation
import SwiftUI

@MainActor
@Observable
public final class HomeViewModel {
    public let bluetoothManager: BluetoothManager

    public init(bluetoothManager: BluetoothManager? = nil) {
        self.bluetoothManager = bluetoothManager ?? BluetoothManager.shared
    }

    public var devices: [BluetoothDevice] {
        bluetoothManager.discoveredDevices
    }

    public var state: BluetoothManagerState {
        bluetoothManager.state
    }

    public var status: String {
        bluetoothManager.statusMessage
    }

    public var isScanning: Bool {
        bluetoothManager.isScanning
    }

    public func toggleScan() {
        if bluetoothManager.isScanning {
            bluetoothManager.stopScan()
        } else {
            bluetoothManager.startScan()
        }
    }
}
