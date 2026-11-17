import Foundation

/// A presentation-safe classification of a speed against a posted limit.
/// It deliberately contains no "official measurement" semantics.
enum SpeedBand: String, Sendable {
    case unknown
    case safe
    case nearLimit
    case overLimit

    init(speedKmh: Double?, limitKmh: Int) {
        guard let speedKmh, speedKmh.isFinite else {
            self = .unknown
            return
        }

        let limit = Double(limitKmh)
        if speedKmh > limit + 0.5 {
            self = .overLimit
        } else if speedKmh >= limit - 5 {
            self = .nearLimit
        } else {
            self = .safe
        }
    }

    var label: String {
        switch self {
        case .unknown: return "Nav datu"
        case .safe: return "Limita robežās"
        case .nearLimit: return "Pie limita"
        case .overLimit: return "Virs limita"
        }
    }
}
