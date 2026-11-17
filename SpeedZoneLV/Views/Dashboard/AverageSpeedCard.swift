import SwiftUI

struct AverageSpeedCard: View {
    let snapshot: RideSnapshot

    private var averageText: String {
        guard let average = snapshot.averageSpeedKmh else { return "—" }
        return Fmt.speed(average)
    }

    private var predictedText: String {
        guard let predicted = snapshot.predictedAverageKmh else { return "—" }
        return "\(Fmt.speed(predicted)) km/h"
    }

    private var recommendedText: String {
        guard let recommended = snapshot.recommendedAverageKmh else { return "—" }
        if recommended <= 0.2 { return "Nav iespējams" }
        // Never advise exceeding the personal target, even when the remaining
        // average could mathematically be higher and still keep the zone
        // average at the target.
        if recommended >= Double(snapshot.targetSpeedKmh) {
            return "≤ \(Fmt.speedLimit(snapshot.targetSpeedKmh))"
        }
        return "\(Fmt.speed(recommended)) km/h"
    }

    private var recommendedColor: Color {
        guard let recommended = snapshot.recommendedAverageKmh else { return Theme.textTertiary }
        if recommended <= 0.2 { return Theme.red }
        return Theme.textPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                SectionLabel("Vidējais kontrolē")
                Spacer()
                StatusPill(text: snapshot.averageBand.label, color: snapshot.averageBand.tint)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(averageText)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText(value: snapshot.averageSpeedKmh ?? 0))
                    .animation(.easeOut(duration: 0.28), value: snapshot.averageSpeedKmh)

                Text("km/h")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                HStack(spacing: 10) {
                    if snapshot.targetSpeedKmh != snapshot.zone.speedLimitKmh {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("MĒRĶIS")
                                .font(.system(size: 8.5, weight: .bold))
                                .tracking(1.2)
                                .foregroundStyle(Theme.amber)
                            Text("\(snapshot.targetSpeedKmh)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.amber)
                        }
                    }

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("LIMITS")
                            .font(.system(size: 8.5, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textTertiary)

                        Text("\(snapshot.zone.speedLimitKmh)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 1)

            MeasurementPredictionRow(
                icon: "flag.checkered",
                iconTint: Theme.ice,
                label: "Prognozētais vidējais finišā",
                value: predictedText,
                valueTint: snapshot.predictedBand.tint
            )

            MeasurementPredictionRow(
                icon: "chart.line.uptrend.xyaxis",
                iconTint: Theme.violet,
                label: "Ieteicamais atlikušajā posmā",
                value: recommendedText,
                valueTint: recommendedColor
            )

            if let predicted = snapshot.predictedAverageKmh,
               predicted > Double(snapshot.targetSpeedKmh) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.top, 1)

                    Text("Prognoze pārsniedz tavu mērķi par \(Fmt.speed(predicted - Double(snapshot.targetSpeedKmh))) km/h. Oficiālais limits paliek \(snapshot.zone.speedLimitKmh) km/h.")
                        .font(.system(size: 11, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Theme.amber)
                .padding(.top, 1)
            }
        }
        .dashboardCard()
    }
}

private struct MeasurementPredictionRow: View {
    let icon: String
    let iconTint: Color
    let label: String
    let value: String
    let valueTint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(iconTint)
                .frame(width: 26, height: 26)
                .background {
                    Circle().fill(iconTint.opacity(0.11))
                }

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(valueTint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

struct ApproachCard: View {
    let snapshot: RideSnapshot

    private var distanceValue: String {
        guard let distance = snapshot.distanceToEntryMeters else { return "—" }
        return Fmt.distance(distance)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("Līdz kontroles zonai")

                    Text(distanceValue)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: snapshot.distanceToEntryMeters ?? 0))
                        .animation(.easeOut(duration: 0.3), value: snapshot.distanceToEntryMeters)

                    Text("Mērījums sāksies automātiski, šķērsojot sākuma līniju.")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(Theme.ice.opacity(0.10))
                        .frame(width: 54, height: 54)

                    Image(systemName: "location.north.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Theme.ice)
                }
            }

            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 1)

            HStack(spacing: 0) {
                approachInfo(title: "Posma garums", value: Fmt.distance(snapshot.zone.officialLengthMeters))
                Spacer()
                approachInfo(title: "Oficiālais limits", value: Fmt.speedLimit(snapshot.zone.speedLimitKmh))
                if snapshot.targetSpeedKmh != snapshot.zone.speedLimitKmh {
                    Spacer()
                    approachInfo(title: "Tavs mērķis", value: Fmt.speedLimit(snapshot.targetSpeedKmh))
                }
            }
        }
        .dashboardCard()
    }

    private func approachInfo(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(Theme.textTertiary)

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
