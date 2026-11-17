import ActivityKit
import SwiftUI
import WidgetKit

private enum LiveColors {
    static let background = Color(red: 0.02, green: 0.027, blue: 0.039)
    static let surface = Color(red: 0.055, green: 0.086, blue: 0.118)
    static let mint = Color(red: 0.208, green: 0.902, blue: 0.643)
    static let ice = Color(red: 0.435, green: 0.659, blue: 1.0)
    static let amber = Color(red: 1.0, green: 0.761, blue: 0.294)
    static let textPrimary = Color(red: 0.957, green: 0.969, blue: 0.984)
    static let textSecondary = Color(red: 0.573, green: 0.612, blue: 0.678)
}

private enum LiveFormat {
    static func speed(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return String(Int(value.rounded()))
    }

    static func optionalSpeed(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "—" }
        return speed(value)
    }

    static func distance(_ meters: Double) -> String {
        guard meters.isFinite, meters >= 0 else { return "—" }
        if meters >= 1_000 {
            let text = String(format: "%.1f", meters / 1_000)
                .replacingOccurrences(of: ".", with: ",")
            return "\(text) km"
        }
        return "\(Int(meters.rounded())) m"
    }

    static func duration(_ interval: TimeInterval) -> String {
        guard interval.isFinite, interval >= 0 else { return "—" }
        let total = Int(interval.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    static func phase(_ raw: String) -> String {
        switch raw {
        case "approaching": return "Pieejot"
        case "active": return "Mērījums"
        case "completed": return "Pabeigts"
        default: return "GPS"
        }
    }

    static func progress(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

struct SpeedZoneLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpeedZoneActivityAttributes.self) { context in
            SpeedZoneLockScreenView(context: context)
                .activityBackgroundTint(LiveColors.background)
                .activitySystemActionForegroundColor(LiveColors.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(context.attributes.road)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(context.state.isDemo ? LiveColors.amber : LiveColors.mint)
                        Text(context.attributes.zoneName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(LiveColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(LiveFormat.phase(context.state.phase).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(LiveColors.textSecondary)
                        Text("LIMITS \(context.state.speedLimitKmh)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(LiveColors.textPrimary)

                        if context.state.targetSpeedKmh != context.state.speedLimitKmh {
                            Text("MĒRĶIS \(context.state.targetSpeedKmh)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(LiveColors.amber)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 6) {
                        Text(LiveFormat.speed(context.state.currentSpeedKmh))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(LiveColors.textPrimary)
                            .monospacedDigit()
                        Text("km/h")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(LiveColors.textSecondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: LiveFormat.progress(context.state.progress))
                            .tint(LiveColors.mint)

                        HStack {
                            if context.state.phase == "approaching",
                               let entry = context.state.distanceToEntryMeters {
                                Text("Līdz sākumam \(LiveFormat.distance(entry))")
                            } else {
                                Text("Vidējais \(LiveFormat.optionalSpeed(context.state.averageSpeedKmh))")
                            }
                            Spacer()
                            Text("Atlikuši \(LiveFormat.distance(context.state.remainingDistanceMeters))")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(LiveColors.textSecondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "speedometer")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LiveColors.mint)
            } compactTrailing: {
                Text(LiveFormat.speed(context.state.currentSpeedKmh))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LiveColors.textPrimary)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.state.phase == "active" ? "speedometer" : "location.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(context.state.phase == "active" ? LiveColors.mint : LiveColors.ice)
            }
        }
    }
}

private struct SpeedZoneLockScreenView: View {
    let context: ActivityViewContext<SpeedZoneActivityAttributes>

    private var state: SpeedZoneActivityAttributes.ContentState {
        context.state
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "speedometer")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiveColors.mint)

                Text(context.attributes.road)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(state.isDemo ? LiveColors.amber : LiveColors.mint)

                Text(context.attributes.zoneName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LiveColors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(LiveFormat.phase(state.phase).uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(LiveColors.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(LiveFormat.speed(state.currentSpeedKmh))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(LiveColors.textPrimary)
                    .monospacedDigit()

                Text("km/h")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(LiveColors.textSecondary)

                Spacer()

                LiveMetric(label: "VIDĒJAIS", value: LiveFormat.optionalSpeed(state.averageSpeedKmh), tint: LiveColors.mint)
                LiveMetric(label: "LIMITS", value: "\(state.speedLimitKmh)", tint: LiveColors.textSecondary)

                if state.targetSpeedKmh != state.speedLimitKmh {
                    LiveMetric(label: "MĒRĶIS", value: "\(state.targetSpeedKmh)", tint: LiveColors.amber)
                }
            }

            ProgressView(value: LiveFormat.progress(state.progress))
                .tint(LiveColors.mint)

            HStack {
                if state.phase == "approaching", let entry = state.distanceToEntryMeters {
                    Label("Līdz sākumam \(LiveFormat.distance(entry))", systemImage: "location.north.fill")
                } else {
                    Label(LiveFormat.distance(state.remainingDistanceMeters), systemImage: "road.lanes")
                }
                Spacer()
                Label(LiveFormat.duration(state.elapsed), systemImage: "clock")
                if let accuracy = state.accuracyMeters {
                    Spacer()
                    Label("±\(Int(accuracy.rounded())) m", systemImage: "location.fill")
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(LiveColors.textSecondary)
        }
        .padding(16)
        .background(LiveColors.background)
    }
}

private struct LiveMetric: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(LiveColors.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
    }
}
