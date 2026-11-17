import SwiftUI

struct HistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: TripRecord

    private var statusText: String {
        if record.averageSpeedKmh > Double(record.speedLimitKmh) + 0.5 {
            return "Virs oficiālā limita"
        }
        if record.averageSpeedKmh > Double(record.resolvedTargetSpeedKmh) + 0.5 {
            return "Virs tava mērķa"
        }
        return "Mērķa robežās"
    }

    private var statusColor: Color {
        if record.averageSpeedKmh > Double(record.speedLimitKmh) + 0.5 { return Theme.red }
        if record.averageSpeedKmh > Double(record.resolvedTargetSpeedKmh) + 0.5 { return Theme.amber }
        return Theme.mint
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        summaryCard

                        SpeedProfileChart(
                            samples: record.speedSamples,
                            officialLimitKmh: record.speedLimitKmh,
                            targetKmh: record.resolvedTargetSpeedKmh,
                            zoneLengthMeters: record.distanceMeters
                        )
                        .dashboardCard()

                        detailsCard

                        DisclaimerFooter()
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Mērījuma detaļas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aizvērt") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(record.road)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(record.isDemo ? Theme.amber : Theme.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(record.isDemo ? Theme.amber.opacity(0.10) : Color.white.opacity(0.055))
                    }

                if record.isDemo {
                    Text("DEMO")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(Theme.amber)
                }

                Spacer()
                StatusPill(text: statusText, color: statusColor)
            }

            Text(record.zoneName)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)

            Text(Fmt.dateTime(record.startedAt))
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Theme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Fmt.speed(record.averageSpeedKmh))
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(statusColor)
                Text("km/h")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("OFICIĀLAIS")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(record.speedLimitKmh)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                if record.resolvedTargetSpeedKmh != record.speedLimitKmh {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("MĒRĶIS")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(Theme.amber)
                        Text("\(record.resolvedTargetSpeedKmh)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.amber)
                    }
                }
            }
        }
        .dashboardCard()
    }

    private var detailsCard: some View {
        let metrics = record.metrics
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Visi dati")

            LazyVGrid(columns: columns, spacing: 10) {
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
                    icon: "exclamationmark.triangle.fill",
                    label: "Virs oficiālā",
                    value: metrics.overOfficialLimitFraction.map(Fmt.percent) ?? "—",
                    accent: Theme.red
                )

                MetricTile(
                    icon: "road.lanes",
                    label: "Attālums",
                    value: Fmt.distance(record.distanceMeters),
                    accent: Theme.mint
                )

                MetricTile(
                    icon: "clock",
                    label: "Laiks",
                    value: Fmt.duration(record.duration),
                    accent: Theme.ice
                )
            }

            Text("Ātruma līkne satur \(record.speedSamples.count) GPS punktus. Vecākiem ierakstiem līkne var būt tukša.")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dashboardCard()
    }
}
