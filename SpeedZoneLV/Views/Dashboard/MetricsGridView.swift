import SwiftUI

struct MetricsGridView: View {
    let snapshot: RideSnapshot

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var startSpeedValue: String {
        guard let startSpeed = snapshot.startSpeedKmh else { return "—" }
        return Fmt.speedRounded(startSpeed)
    }

    private var remainingTimeValue: String {
        guard let remainingTime = snapshot.estimatedRemainingTime else { return "—" }
        return Fmt.duration(remainingTime)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            MetricTile(
                icon: "flag.checkered",
                label: "Sākuma ātrums",
                value: startSpeedValue,
                unit: snapshot.startSpeedKmh == nil ? nil : "km/h",
                accent: Theme.ice
            )

            MetricTile(
                icon: "timer",
                label: "Pagājis laiks",
                value: Fmt.duration(snapshot.elapsed),
                accent: Theme.violet
            )

            MetricTile(
                icon: "road.lanes",
                label: "Atlikušais attālums",
                value: Fmt.distance(snapshot.remainingDistanceMeters),
                accent: Theme.mint
            )

            MetricTile(
                icon: "clock",
                label: "Atlikušais laiks",
                value: remainingTimeValue,
                accent: Theme.amber
            )
        }
    }
}

struct ZoneProgressCard: View {
    let snapshot: RideSnapshot

    private var progress: Double {
        min(max(snapshot.progress, 0), 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel("Posma gaita")

                Spacer()

                Text(Fmt.percent(progress))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.mint)
                    .contentTransition(.numericText(value: progress))
                    .animation(.easeOut(duration: 0.3), value: progress)
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                let markerX = max(min(width * progress, width - 7), 7)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.mintDeep, Theme.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(width * progress, 8), height: 8)
                        .shadow(color: Theme.mint.opacity(0.35), radius: 8)

                    Circle()
                        .fill(Theme.textPrimary)
                        .frame(width: 14, height: 14)
                        .shadow(color: Theme.mint.opacity(0.7), radius: 7)
                        .position(x: markerX, y: 7)
                }
            }
            .frame(height: 14)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SĀKUMS")
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Theme.textTertiary)

                    Text("0 m")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("FINIŠS")
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Theme.textTertiary)

                    Text(Fmt.distance(snapshot.zone.officialLengthMeters))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack {
                Text("Nobraukts \(Fmt.distance(snapshot.distanceTravelledMeters))")
                Spacer()
                Text("no \(Fmt.distance(snapshot.zone.officialLengthMeters))")
            }
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(Theme.textTertiary)
        }
        .dashboardCard()
    }
}
