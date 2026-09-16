import Foundation
import CoreBluetooth
import Combine

public enum BluetoothManagerState: String {
    case unavailable
    case poweredOff
    case unauthorized
    case unsupported
    case ready
    case scanning
    case stopped

    public var title: String {
        switch self {
        case .unavailable:
            return "Bluetooth unavailable"
        case .poweredOff:
            return "Bluetooth is turned off"
        case .unauthorized:
            return "Bluetooth permission is required"
        case .unsupported:
            return "Bluetooth unsupported"
        case .ready:
            return "Ready to scan"
        case .scanning:
            return "Scanning..."
        case .stopped:
            return "Scan paused"
        }
    }
}

@MainActor
public final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published public var state: BluetoothManagerState = .unsupported
    @Published public var isScanning = false
    @Published public var discoveredDevices: [BluetoothDevice] = []
    @Published public var statusMessage: String = "Bluetooth access is required to discover nearby devices."

    public static let shared = BluetoothManager()

    private var centralManager: CBCentralManager?
    private let staleThreshold: TimeInterval = 45
    private let scanCooldown: TimeInterval = 0.25
    private let scanQueue = DispatchQueue(label: "FindAir.BluetoothScanQueue")
    private var filterCache: [UUID: RSSIFilter] = [:]
    private var historyCache: [UUID: [Double]] = [:]
    private var shouldScan = false

    override public init() {
        super.init()
    }

    public func startScan() {
        guard let manager = centralManager else {
            state = .unavailable
            return
        }

        switch manager.state {
        case .poweredOn:
            shouldScan = true
            if !isScanning {
                manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                isScanning = true
                state = .scanning
                statusMessage = "Scanning for nearby devices..."
            }
        case .poweredOff:
            shouldScan = false
            isScanning = false
            state = .poweredOff
            statusMessage = "Turn on Bluetooth in Settings to scan for nearby devices."
        case .unauthorized:
            shouldScan = false
            isScanning = false
            state = .unauthorized
            statusMessage = "Bluetooth permission is required to discover nearby devices."
        case .unsupported:
            shouldScan = false
            isScanning = false
            state = .unsupported
            statusMessage = "This device does not support Bluetooth scanning."
        case .resetting:
            state = .ready
        case .unknown:
            state = .ready
        @unknown default:
            state = .unavailable
        }
    }

    public func stopScan() {
        shouldScan = false
        isScanning = false
        centralManager?.stopScan()
        state = .stopped
        statusMessage = "Scan paused."
    }

    public func requestAuthorizationIfNeeded() {
        shouldScan = true

        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: scanQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        } else if centralManager?.state == .poweredOn {
            startScan()
        }
    }

    public nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            updateState(for: central.state)

            if central.state == .poweredOn && shouldScan {
                startScan()
            }
        }
    }

    public nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            let rawRSSI = RSSI.intValue
            let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? ""
            let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !displayName.isEmpty else {
                return
            }

            let existingIndex = discoveredDevices.firstIndex { $0.id == peripheral.identifier }
            let filter = filterCache[peripheral.identifier, default: RSSIFilter()]
            let smoothed = filter.update(rawRSSI: rawRSSI)
            let signalLevel = SignalStrengthCalculator.signalLevel(for: smoothed)
            let signalStrength = SignalStrengthCalculator.strength(for: smoothed)

            let device = BluetoothDevice(
                id: peripheral.identifier,
                name: displayName,
                rssi: rawRSSI,
                smoothedRSSI: smoothed,
                signalStrength: signalStrength,
                signalLevel: signalLevel,
                lastSeen: Date(),
                peripheral: peripheral,
                category: inferredCategory(for: displayName)
            )

            var updatedDevice = device
            if let index = existingIndex {
                let previous = discoveredDevices[index]
                let history = historyCache[peripheral.identifier] ?? [previous.smoothedRSSI]
                let newHistory = (history + [smoothed]).suffix(6)
                historyCache[peripheral.identifier] = Array(newHistory)
                updatedDevice.trend = SignalStrengthCalculator.trend(for: Array(newHistory))
                updatedDevice.isFavorite = previous.isFavorite
                updatedDevice.category = previous.category
                updatedDevice.name = displayName
            } else {
                historyCache[peripheral.identifier] = [smoothed]
                updatedDevice.trend = .stable
            }

            filterCache[peripheral.identifier] = filter

            if let index = existingIndex {
                discoveredDevices[index] = updatedDevice
            } else {
                discoveredDevices.append(updatedDevice)
            }

            let cutoff = Date().addingTimeInterval(-staleThreshold)
            if discoveredDevices.contains(where: { $0.lastSeen < cutoff }) {
                discoveredDevices.removeAll { $0.lastSeen < cutoff }
            }

            if discoveredDevices.count == 0 {
                statusMessage = "No nearby Bluetooth devices found. Move closer and try scanning again."
            } else {
                statusMessage = "Nearby devices are updating in real time."
            }
        }
    }

    public func updateFavorites(_ favorites: Set<UUID>) {
        discoveredDevices = discoveredDevices.map { device in
            var updated = device
            updated.isFavorite = favorites.contains(device.id)
            return updated
        }
    }

    private func inferredCategory(for name: String) -> DeviceCategory {
        let lowerName = name.lowercased()
        if lowerName.contains("airpod") || lowerName.contains("headphone") || lowerName.contains("earbud") || lowerName.contains("speaker") || lowerName.contains("audio") {
            return .audio
        }
        if lowerName.contains("watch") || lowerName.contains("fitbit") || lowerName.contains("band") {
            return .wearables
        }
        if lowerName.contains("iphone") || lowerName.contains("ipad") || lowerName.contains("mac") || lowerName.contains("phone") || lowerName.contains("tablet") {
            return .phonesTablets
        }
        return .other
    }

    private func updateState(for state: CBManagerState) {
        switch state {
        case .unknown:
            self.state = .ready
        case .resetting:
            self.state = .ready
        case .unsupported:
            self.state = .unsupported
        case .unauthorized:
            self.state = .unauthorized
        case .poweredOff:
            self.state = .poweredOff
        case .poweredOn:
            self.state = isScanning ? .scanning : .ready
        @unknown default:
            self.state = .unavailable
        }
    }

    public func pruneStaleDevices() {
        let cutoff = Date().addingTimeInterval(-staleThreshold)
        discoveredDevices = discoveredDevices.filter { $0.lastSeen >= cutoff }
    }
}
