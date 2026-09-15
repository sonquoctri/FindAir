import Foundation

public final class RSSIFilter {
    public var alpha: Double
    private var previousRSSI: Double?

    public init(alpha: Double = 0.45) {
        self.alpha = alpha
    }

    public func update(rawRSSI: Int) -> Double {
        let value = Double(rawRSSI)
        let smoothed: Double

        if let previous = previousRSSI {
            smoothed = alpha * value + (1.0 - alpha) * previous
        } else {
            smoothed = value
        }

        previousRSSI = smoothed
        return smoothed
    }

    public func reset() {
        previousRSSI = nil
    }
}
