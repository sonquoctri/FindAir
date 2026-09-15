import Foundation
import CoreBluetooth

public struct BluetoothDevice: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var rssi: Int
    public var smoothedRSSI: Double
    public var signalStrength: Double
    public var signalLevel: SignalLevel
    public var lastSeen: Date
    public var peripheral: CBPeripheral?
    public var isFavorite: Bool = false
    public var category: DeviceCategory = .other
    public var trend: RSSITrend = .stable

    public init(
        id: UUID,
        name: String,
        rssi: Int,
        smoothedRSSI: Double,
        signalStrength: Double,
        signalLevel: SignalLevel,
        lastSeen: Date,
        peripheral: CBPeripheral? = nil,
        isFavorite: Bool = false,
        category: DeviceCategory = .other,
        trend: RSSITrend = .stable
    ) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.smoothedRSSI = smoothedRSSI
        self.signalStrength = signalStrength
        self.signalLevel = signalLevel
        self.lastSeen = lastSeen
        self.peripheral = peripheral
        self.isFavorite = isFavorite
        self.category = category
        self.trend = trend
    }

    public var displayName: String {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Unknown Device"
        }
        return name
    }

    public var shortSignalDescription: String {
        signalLevel.title
    }

    public var lastSeenText: String {
        let interval = Date().timeIntervalSince(lastSeen)
        if interval < 60 {
            return "Just now"
        }

        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) min ago"
        }

        let hours = Int(minutes / 60)
        return "\(hours) hr ago"
    }
}

public enum DeviceCategory: String, CaseIterable {
    case all
    case audio
    case wearables
    case phonesTablets
    case other

    public var title: String {
        switch self {
        case .all:
            return "All"
        case .audio:
            return "Audio"
        case .wearables:
            return "Wearables"
        case .phonesTablets:
            return "Phones/Tablets"
        case .other:
            return "Other"
        }
    }
}
