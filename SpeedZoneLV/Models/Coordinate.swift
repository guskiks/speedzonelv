import CoreLocation
import Foundation

/// A lightweight, Codable coordinate used by the zone database.
/// CoreLocation types are intentionally kept out of the JSON schema.
struct Coordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isValid: Bool {
        latitude.isFinite
            && longitude.isFinite
            && latitude >= -90
            && latitude <= 90
            && longitude >= -180
            && longitude <= 180
    }

    func distance(to other: Coordinate) -> CLLocationDistance {
        let lhs = CLLocation(latitude: latitude, longitude: longitude)
        let rhs = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return lhs.distance(from: rhs)
    }
}
