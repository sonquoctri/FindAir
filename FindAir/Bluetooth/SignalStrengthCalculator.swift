import Foundation

public enum SignalStrengthCalculator {
    public static let defaultThresholds: [SignalLevel: ClosedRange<Double>] = [
        .veryFar: (-100.0)...(-80.0),
        .far: (-79.0)...(-70.0),
        .nearby: (-69.0)...(-60.0),
        .close: (-59.0)...(-45.0),
        .veryClose: (-44.0)...(0.0)
    ]

    public static func signalLevel(for rssi: Double, thresholds: [SignalLevel: ClosedRange<Double>] = defaultThresholds) -> SignalLevel {
        for level in [SignalLevel.veryFar, .far, .nearby, .close, .veryClose] {
            if let range = thresholds[level], range.contains(rssi) {
                return level
            }
        }

        if rssi <= -80 {
            return .veryFar
        }
        if rssi <= -70 {
            return .far
        }
        if rssi <= -60 {
            return .nearby
        }
        if rssi <= -45 {
            return .close
        }
        return .veryClose
    }

    public static func strength(for rssi: Double) -> Double {
        let normalized = (rssi + 100.0) / 65.0
        return max(0.0, min(1.0, normalized))
    }

    public static func trend(for recentValues: [Double]) -> RSSITrend {
        guard recentValues.count >= 3 else {
            return .stable
        }

        let recent = recentValues.suffix(3)
        let older = recentValues.prefix(max(1, recentValues.count - 3))
        let recentAverage = recent.reduce(0, +) / Double(recent.count)
        let olderAverage = older.reduce(0, +) / Double(older.count)

        if recentAverage < olderAverage - 2.0 {
            return .gettingCloser
        }
        if recentAverage > olderAverage + 2.0 {
            return .gettingFarther
        }
        return .stable
    }
}
