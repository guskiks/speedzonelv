import SwiftUI

struct ZoneHeaderCard: View {
    let snapshot: RideSnapshot

    private var phaseColor: Color {
        switch snapshot.phase {
        case .approaching: return Theme.ice
        case .active: return Theme.mint
        case .completed: return Theme.ice
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                StatusPill(text: snapshot.phase.label, color: phaseColor)

                Spacer()

                Text(snapshot.zone.road)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(snapshot.zone.isDemo ? Theme.amber : Theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        Capsule()
                            .fill(snapshot.zone.isDemo ? Theme.amber.opacity(0.10) : Color.white.opacity(0.055))
                            .overlay {
                                Capsule().stroke(
                                    snapshot.zone.isDemo ? Theme.amber.opacity(0.25) : Theme.strokeStrong,
                                    lineWidth: 1
                                )
                            }
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Vidējā ātruma kontrole")

                Text(snapshot.zone.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))

                    Text(snapshot.zone.directionLabel)
                    Text("·")
                    Text(Fmt.distance(snapshot.zone.officialLengthMeters))
                    Text("·")
                    Text(Fmt.speedLimit(snapshot.zone.speedLimitKmh))
                    if snapshot.targetSpeedKmh != snapshot.zone.speedLimitKmh {
                        Text("·")
                        Text("mērķis \(snapshot.targetSpeedKmh)")
                            .foregroundStyle(Theme.amber)
                    }
                }
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            }
        }
        .dashboardCard()
    }
}

struct LiveRideView: View {
    @EnvironmentObject private var appearance: AppearanceSettings

    let snapshot: RideSnapshot
    let onStop: () -> Void
    let stopLabel: String

    var body: some View {
        VStack(spacing: 8) {
            if snapshot.phase == .approaching {
                ZoneHeaderCard(snapshot: snapshot)
                if appearance.showsApproachDetails {
                    ApproachCard(snapshot: snapshot)
                }
            } else {
                CompactLiveHeader(snapshot: snapshot)
                CompactCurrentSpeed(snapshot: snapshot)
                CompactRideSummary(snapshot: snapshot)
                CompactZoneLine(snapshot: snapshot)

                if appearance.showsSpeedCurve {
                    SpeedProfileChart(
                        samples: snapshot.samples,
                        officialLimitKmh: snapshot.zone.speedLimitKmh,
                        targetKmh: snapshot.targetSpeedKmh,
                        zoneLengthMeters: snapshot.zone.officialLengthMeters,
                        chartHeight: 112
                    )
                    .dashboardCard(padding: 9)
                }
            }

            VStack(spacing: 8) {
                Button(stopLabel, action: onStop)
                    .buttonStyle(SecondaryButtonStyle())

                HStack(spacing: 5) {
                    Image(systemName: snapshot.isDemo ? "sparkles" : "location.fill")
                    Text(footerText)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            }
            .padding(.top, 2)
        }
    }

    private var footerText: String {
        if snapshot.isDemo {
            return "Demo režīms · simulēti brauciena dati"
        }
        return "GPS mērījums · informatīvs, nav oficiāls"
    }
}

private struct CompactLiveHeader: View {
    let snapshot: RideSnapshot

    var body: some View {
        HStack {
            Text("MĒRĪŠANA")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("LIMITS \(snapshot.zone.speedLimitKmh)")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 4)
    }
}

private struct CompactCurrentSpeed: View {
    let snapshot: RideSnapshot

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(snapshot.currentBand.tint)
                    .frame(width: 8, height: 8)
                Text(snapshot.currentBand.label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(snapshot.currentBand.tint)
            }

            Text(Fmt.speed(snapshot.currentSpeedKmh))
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(snapshot.currentBand.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("KM/H · PAŠREIZĒJAIS ĀTRUMS")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
    }
}

private struct CompactZoneLine: View {
    let snapshot: RideSnapshot

    var body: some View {
        HStack(spacing: 5) {
            Text(snapshot.zone.road)
                .font(.system(size: 12, weight: .semibold))
            Text("·")
            Text(snapshot.zone.name)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 8)
            Text(Fmt.distance(snapshot.zone.officialLengthMeters))
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 4)
    }
}

/// Compact live-readout: all important values stay visible while driving.
private struct CompactRideSummary: View {
    let snapshot: RideSnapshot

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var recommended: String {
        guard let value = snapshot.recommendedAverageKmh else { return "—" }
        if value <= 0.2 { return "Nav iespējams" }
        return value >= Double(snapshot.targetSpeedKmh)
            ? "≤ \(Fmt.speedLimit(snapshot.targetSpeedKmh))"
            : "\(Fmt.speed(value)) km/h"
    }

    private var recommendedTint: Color {
        guard let value = snapshot.recommendedAverageKmh else { return Theme.textTertiary }
        if value <= 0.2 { return Theme.red }
        if value >= Double(snapshot.targetSpeedKmh) { return Theme.amber }
        return Theme.mint
    }

    private func speed(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Fmt.speed(value)) km/h"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("POSMA DATI")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text(Fmt.percent(snapshot.progress))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.mint)
            }

            ProgressView(value: min(max(snapshot.progress, 0), 1))
                .tint(Theme.mint)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 12) {
                compactMetric("Vidējais", speed(snapshot.averageSpeedKmh), snapshot.averageBand.tint)
                compactMetric("Prognoze", speed(snapshot.predictedAverageKmh), snapshot.predictedBand.tint)
                compactMetric("Ieteicamais", recommended, recommendedTint)
                compactMetric("Tagad", speed(snapshot.currentSpeedKmh), snapshot.currentBand.tint)
                compactMetric("Sākums", speed(snapshot.startSpeedKmh), Theme.ice)
                compactMetric("Laiks", Fmt.duration(snapshot.elapsed), Theme.violet)
                compactMetric("Attālums", Fmt.distance(snapshot.remainingDistanceMeters), Theme.mint)
                compactMetric("Atlikušais", snapshot.estimatedRemainingTime.map { Fmt.duration($0) } ?? "—", Theme.amber)
            }
        }
        .dashboardCard(padding: 10)
    }

    private func compactMetric(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 7.5, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
