import CoreLocation
import Foundation

/// Small-distance planar projection around a zone entry. Average-speed
/// sections are road segments; the equirectangular approximation is accurate
/// well below a metre over the lengths involved here.
struct ZoneProjection: Sendable {
    /// Signed distance from the entry along the entry → exit axis. Negative
    /// values are before the entry, positive values are inside/past the zone.
    let alongMeters: Double
    /// Perpendicular distance from the entry → exit line.
    let lateralMeters: Double
    /// Raw geometric entry → exit length.
    let axisLengthMeters: Double
}

enum GeoMath {
    static func bearing(from start: Coordinate, to end: Coordinate) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }

    static func angularDifference(_ first: Double, _ second: Double) -> Double {
        let diff = abs(first - second).truncatingRemainder(dividingBy: 360)
        return diff > 180 ? 360 - diff : diff
    }

    static func projection(of point: Coordinate, entry: Coordinate, exit: Coordinate) -> ZoneProjection {
        let latitudeRadians = entry.latitude * .pi / 180
        let metersPerDegreeLatitude = 111_132.0
        let metersPerDegreeLongitude = 111_320.0 * max(cos(latitudeRadians), 0.01)

        let axisX = (exit.longitude - entry.longitude) * metersPerDegreeLongitude
        let axisY = (exit.latitude - entry.latitude) * metersPerDegreeLatitude
        let pointX = (point.longitude - entry.longitude) * metersPerDegreeLongitude
        let pointY = (point.latitude - entry.latitude) * metersPerDegreeLatitude

        let axisLength = hypot(axisX, axisY)
        guard axisLength > 1 else {
            return ZoneProjection(alongMeters: 0, lateralMeters: hypot(pointX, pointY), axisLengthMeters: axisLength)
        }

        let fraction = (pointX * axisX + pointY * axisY) / (axisLength * axisLength)
        let along = fraction * axisLength
        let perpendicularX = pointX - fraction * axisX
        let perpendicularY = pointY - fraction * axisY
        let lateral = hypot(perpendicularX, perpendicularY)

        return ZoneProjection(alongMeters: along, lateralMeters: lateral, axisLengthMeters: axisLength)
    }

    /// Calculates a destination coordinate from a start point, bearing and
    /// distance. Used only to build an explicitly labelled GPS test corridor.
    static func offset(from start: Coordinate, bearingDegrees: Double, distanceMeters: Double) -> Coordinate {
        let angularDistance = distanceMeters / 6_371_000.0
        let bearing = bearingDegrees * .pi / 180
        let latitude1 = start.latitude * .pi / 180
        let longitude1 = start.longitude * .pi / 180

        let latitude2 = asin(
            sin(latitude1) * cos(angularDistance)
                + cos(latitude1) * sin(angularDistance) * cos(bearing)
        )
        let longitude2 = longitude1 + atan2(
            sin(bearing) * sin(angularDistance) * cos(latitude1),
            cos(angularDistance) - sin(latitude1) * sin(latitude2)
        )

        return Coordinate(
            latitude: latitude2 * 180 / .pi,
            longitude: ((longitude2 * 180 / .pi) + 540)
                .truncatingRemainder(dividingBy: 360) - 180
        )
    }
}

struct ZoneCandidate: Sendable {
    let zone: SpeedZone
    let projection: ZoneProjection
    let distanceToEntryMeters: Double
    let entryBearingDegrees: Double
    let headingDeltaDegrees: Double
    let axisScale: Double

    var alongZoneMeters: Double {
        projection.alongMeters * axisScale
    }

    var lateralMeters: Double {
        projection.lateralMeters
    }

    var headingMatches: Bool {
        headingDeltaDegrees <= ZoneDetectionEngine.bearingToleranceDegrees
    }

    var isInside: Bool {
        alongZoneMeters >= -2 && alongZoneMeters <= zone.officialLengthMeters + 2
    }

    var distanceToEntryForDisplay: Double {
        max(-alongZoneMeters, distanceToEntryMeters)
    }
}

enum ZoneDetectionEngine {
    static let approachRadiusMeters: Double = 1_200
    static let bearingToleranceDegrees: Double = 55
    static let maximumApproachLateralMeters: Double = 300
    static let maximumEntryLateralMeters: Double = 200

    static func bestApproach(zones: [SpeedZone], fix: GPSFix, previous: GPSFix?) -> ZoneCandidate? {
        guard fix.speedKmh >= 8 else { 
            print("[ZoneDetection] bestApproach: speed too low \(fix.speedKmh)kmh")
            return nil 
        }

        let matches = zones.compactMap { zone -> ZoneCandidate? in
            guard let candidate = candidate(zone: zone, fix: fix, previous: previous) else { return nil }
            guard candidate.headingMatches else { 
                print("[ZoneDetection] bestApproach: heading mismatch zone=\(zone.name) delta=\(candidate.headingDeltaDegrees)")
                return nil 
            }
            guard candidate.distanceToEntryMeters <= approachRadiusMeters else { 
                print("[ZoneDetection] bestApproach: too far zone=\(zone.name) dist=\(candidate.distanceToEntryMeters)")
                return nil 
            }
            guard candidate.lateralMeters <= maximumApproachLateralMeters else { 
                print("[ZoneDetection] bestApproach: lateral too far zone=\(zone.name) lateral=\(candidate.lateralMeters)")
                return nil 
            }
            guard candidate.alongZoneMeters <= 30 else { 
                print("[ZoneDetection] bestApproach: already inside zone=\(zone.name) along=\(candidate.alongZoneMeters)")
                return nil 
            }
            return candidate
        }

        let result = matches.min { first, second in
            first.distanceToEntryMeters < second.distanceToEntryMeters
        }
        if let result {
            print("[ZoneDetection] bestApproach SELECTED zone=\(result.zone.name) dist=\(result.distanceToEntryMeters)m")
        }
        return result
    }

    /// Used when the app receives its first usable fix while already inside a
    /// section (for example when the user opens the app mid-zone).
    static func bestInside(zones: [SpeedZone], fix: GPSFix, previous: GPSFix?) -> ZoneCandidate? {
        let matches = zones.compactMap { zone -> ZoneCandidate? in
            guard let candidate = candidate(zone: zone, fix: fix, previous: previous) else { return nil }
            guard candidate.headingMatches else { return nil }
            guard candidate.lateralMeters <= maximumEntryLateralMeters else { 
                print("[ZoneDetection] bestInside: lateral too far zone=\(zone.name) lateral=\(candidate.lateralMeters)")
                return nil 
            }
            guard let inside = insideStartDistance(candidate: candidate) else { return nil }
            guard inside <= candidate.zone.officialLengthMeters else { return nil }
            return candidate
        }

        let result = matches.min { first, second in
            first.alongZoneMeters < second.alongZoneMeters
        }
        if let result {
            print("[ZoneDetection] bestInside SELECTED zone=\(result.zone.name) along=\(result.alongZoneMeters)m")
        }
        return result
    }

    static func candidate(zone: SpeedZone, fix: GPSFix, previous: GPSFix?) -> ZoneCandidate? {
        let entry = zone.effectiveEntry
        let exit = zone.effectiveExit
        let axisLength = entry.distance(to: exit)
        // Remove arbitrary 40m minimum - use official length instead
        guard axisLength > 1 else { 
            print("[ZoneDetection] candidate rejected: axisLength=\(axisLength) zone=\(zone.name)")
            return nil 
        }

        let projection = GeoMath.projection(of: fix.coordinate, entry: entry, exit: exit)
        // Increase lateral tolerance for long/winding zones - use 500m instead of 250m
        guard projection.lateralMeters <= 500 else { 
            print("[ZoneDetection] candidate rejected: lateral=\(projection.lateralMeters) zone=\(zone.name)")
            return nil 
        }

        let entryBearing = GeoMath.bearing(from: entry, to: exit)
        guard let heading = heading(for: fix, previous: previous) else { 
            print("[ZoneDetection] candidate rejected: no heading zone=\(zone.name)")
            return nil 
        }
        let delta = GeoMath.angularDifference(heading, entryBearing)
        let scale = zone.officialLengthMeters / axisLength

        print("[ZoneDetection] candidate OK zone=\(zone.name) along=\(projection.alongMeters * scale)m lateral=\(projection.lateralMeters)m heading=\(heading) bearing=\(entryBearing) delta=\(delta) scale=\(scale)")

        return ZoneCandidate(
            zone: zone,
            projection: projection,
            distanceToEntryMeters: fix.coordinate.distance(to: entry),
            entryBearingDegrees: entryBearing,
            headingDeltaDegrees: delta,
            axisScale: scale
        )
    }

    static func heading(for fix: GPSFix, previous: GPSFix?) -> Double? {
        if fix.hasValidCourse,
           fix.courseAccuracyDegrees >= 0,
           fix.courseAccuracyDegrees <= 65 {
            return fix.courseDegrees
        }

        guard let previous else { return nil }
        let distance = previous.coordinate.distance(to: fix.coordinate)
        guard distance >= 8 else { return nil }
        return GeoMath.bearing(from: previous.coordinate, to: fix.coordinate)
    }

    /// Returns the interpolated instant at which the vehicle crossed the
    /// entry line, or nil when the two fixes do not form a valid forward
    /// crossing.
    static func entryCrossingDate(
        previous: GPSFix,
        current: GPSFix,
        candidate: ZoneCandidate
    ) -> Date? {
        guard candidate.headingMatches else { return nil }

        let entry = candidate.zone.effectiveEntry
        let exit = candidate.zone.effectiveExit
        let previousProjection = GeoMath.projection(of: previous.coordinate, entry: entry, exit: exit)
        let currentProjection = GeoMath.projection(of: current.coordinate, entry: entry, exit: exit)

        guard previousProjection.alongMeters < 0, currentProjection.alongMeters >= 0 else { return nil }
        guard currentProjection.lateralMeters <= maximumEntryLateralMeters else { return nil }
        guard abs(previousProjection.lateralMeters) <= maximumEntryLateralMeters + 30 else { return nil }

        let deltaAlong = currentProjection.alongMeters - previousProjection.alongMeters
        guard deltaAlong > 0 else { return nil }

        let fraction = min(max(-previousProjection.alongMeters / deltaAlong, 0), 1)
        let deltaTime = current.timestamp.timeIntervalSince(previous.timestamp)
        return previous.timestamp.addingTimeInterval(deltaTime * fraction)
    }

    /// Handles the case where the app receives its first usable fix while the
    /// vehicle is already inside the section.
    static func insideStartDistance(candidate: ZoneCandidate) -> Double? {
        guard candidate.lateralMeters <= maximumEntryLateralMeters else { return nil }
        guard candidate.alongZoneMeters >= 0 else { return nil }
        guard candidate.alongZoneMeters <= candidate.zone.officialLengthMeters else { return nil }
        return candidate.alongZoneMeters
    }
}
