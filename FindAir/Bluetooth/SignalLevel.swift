import Foundation

public enum SignalLevel: String, CaseIterable {
    case veryFar
    case far
    case nearby
    case close
    case veryClose

    public var title: String {
        switch self {
        case .veryFar:
            return "Very Far"
        case .far:
            return "Far"
        case .nearby:
            return "Nearby"
        case .close:
            return "Close"
        case .veryClose:
            return "Very Close"
        }
    }

    public var accessibilityTitle: String {
        title
    }

    public var description: String {
        switch self {
        case .veryFar:
            return "Weak signal"
        case .far:
            return "Getting farther"
        case .nearby:
            return "Stable signal"
        case .close:
            return "Strong signal"
        case .veryClose:
            return "Very strong signal"
        }
    }

    public var tint: String {
        switch self {
        case .veryFar:
            return "#7B8AA4"
        case .far:
            return "#8E9EC9"
        case .nearby:
            return "#4FC3A1"
        case .close:
            return "#7AD87A"
        case .veryClose:
            return "#30D158"
        }
    }
}

public enum RSSITrend: String {
    case gettingCloser
    case gettingFarther
    case stable

    public var title: String {
        switch self {
        case .gettingCloser:
            return "Getting Closer"
        case .gettingFarther:
            return "Getting Farther"
        case .stable:
            return "Signal Stable"
        }
    }
}
