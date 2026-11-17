import Foundation

/// Formatting helpers used across the Latvian interface.
/// All user-facing numbers use the Latvian decimal comma.
enum Fmt {
    private static let lvLocale = Locale(identifier: "lv_LV")

    private static let speedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = lvLocale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = lvLocale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = lvLocale
        formatter.dateFormat = "d. MMMM, HH:mm"
        return formatter
    }()

    static func speed(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return speedFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }

    static func speedRounded(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return String(Int(value.rounded()))
    }

    static func distance(_ meters: Double) -> String {
        guard meters.isFinite, meters >= 0 else { return "—" }
        if meters >= 1_000 {
            let kilometers = meters / 1_000
            return "\(distanceFormatter.string(from: NSNumber(value: kilometers)) ?? String(format: "%.1f", kilometers)) km"
        }
        return "\(Int(meters.rounded())) m"
    }

    static func duration(_ interval: TimeInterval) -> String {
        guard interval.isFinite, interval >= 0 else { return "—" }
        let total = Int(interval.rounded())
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func percent(_ fraction: Double) -> String {
        guard fraction.isFinite else { return "0%" }
        return "\(Int((fraction * 100).rounded()))%"
    }

    static func dateTime(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func speedLimit(_ limit: Int) -> String {
        "\(limit) km/h"
    }
}
