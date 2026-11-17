import SwiftUI

struct CompletedMeasurementView: View {
    @EnvironmentObject private var appearance: AppearanceSettings

    let snapshot: RideSnapshot
    let onRestart: () -> Void
    let onClose: () -> Void

    private var averageText: String {
        guard let average = snapshot.averageSpeedKmh else { return "—" }
        return Fmt.speed(average)
    }

    private var targetStatusText: String {
        guard let average = snapshot.averageSpeedKmh else { return "Nav datu" }
        if average > Double(snapshot.zone.speedLimitKmh) + 0.5 {
            return "Virs oficiālā limita par \(Fmt.speed(average - Double(snapshot.zone.speedLimitKmh))) km/h"
        }
        if average > Double(snapshot.targetSpeedKmh) + 0.5 {
            return "Virs tava mērķa par \(Fmt.speed(average - Double(snapshot.targetSpeedKmh))) km/h"
        }
        return "Tava mērķa robežās"
    }

    private var targetStatusColor: Color {
        guard let average = snapshot.averageSpeedKmh else { return Theme.textTertiary }
        if average > Double(snapshot.zone.speedLimitKmh) + 0.5 { return Theme.red }
        if average > Double(snapshot.targetSpeedKmh) + 0.5 { return Theme.amber }
        return Theme.mint
    }

    private var restartTitle: String {
        if snapshot.isDemo { return "Atkārtot demo" }
        return "Sākt jaunu braucienu"
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    StatusPill(text: "Pabeigts", color: Theme.mint)
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
                    SectionLabel("Vidējais kontrolē")

                    Text(snapshot.zone.name)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(Fmt.dateTime(snapshot.capturedAt))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(averageText)
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(targetStatusColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Text("km/h")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("OFICIĀLAIS")
                            .font(.system(size: 8.5, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textTertiary)

                        Text("\(snapshot.zone.speedLimitKmh)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    }

                    if snapshot.targetSpeedKmh != snapshot.zone.speedLimitKmh {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("MĒRĶIS")
                                .font(.system(size: 8.5, weight: .bold))
                                .tracking(1.2)
                                .foregroundStyle(Theme.amber)

                            Text("\(snapshot.targetSpeedKmh)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.amber)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: targetStatusColor == Theme.red ? "exclamationmark.triangle.fill" : "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text(targetStatusText)
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundStyle(targetStatusColor)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background {
                    Capsule().fill(targetStatusColor.opacity(0.10))
                }

                Rectangle()
                    .fill(Theme.stroke)
                    .frame(height: 1)

                summaryGrid
            }
            .dashboardCard()

            if appearance.showsSpeedCurve {
                SpeedProfileChart(
                    samples: snapshot.samples,
                    officialLimitKmh: snapshot.zone.speedLimitKmh,
                    targetKmh: snapshot.targetSpeedKmh,
                    zoneLengthMeters: snapshot.zone.officialLengthMeters
                )
                .dashboardCard()
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(snapshot.isDemo
                     ? "Demo mērījums saglabāts vēsturē"
                     : "Mērījums saglabāts vēsturē ar pilnu ātruma līkni")
                    .font(.system(size: 10.5, weight: .medium))
            }
            .foregroundStyle(Theme.textTertiary)

            Button(restartTitle, action: onRestart)
                .buttonStyle(PrimaryButtonStyle())

            Button("Aizvērt kopsavilkumu", action: onClose)
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var summaryGrid: some View {
        let metrics = snapshot.metrics
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return LazyVGrid(columns: columns, spacing: 10) {
            MetricTile(
                icon: "arrow.up.circle.fill",
                label: "Maks. ātrums",
                value: metrics.maximumSpeedKmh.map(Fmt.speed) ?? "—",
                unit: metrics.maximumSpeedKmh == nil ? nil : "km/h",
                accent: Theme.amber
            )

            MetricTile(
                icon: "arrow.down.circle.fill",
                label: "Min. ātrums",
                value: metrics.minimumSpeedKmh.map(Fmt.speed) ?? "—",
                unit: metrics.minimumSpeedKmh == nil ? nil : "km/h",
                accent: Theme.ice
            )

            MetricTile(
                icon: "target",
                label: "Virs mērķa",
                value: metrics.overTargetFraction.map(Fmt.percent) ?? "—",
                accent: Theme.violet
            )

            MetricTile(
                icon: "road.lanes",
                label: "Attālums",
                value: Fmt.distance(snapshot.distanceTravelledMeters),
                accent: Theme.mint
            )

            MetricTile(
                icon: "clock",
                label: "Laiks",
                value: Fmt.duration(snapshot.elapsed),
                accent: Theme.ice
            )

            MetricTile(
                icon: "flag.fill",
                label: "Sākuma ātrums",
                value: snapshot.startSpeedKmh.map { Fmt.speedRounded($0) } ?? "—",
                unit: snapshot.startSpeedKmh == nil ? nil : "km/h",
                accent: Theme.mint
            )
        }
    }
}
