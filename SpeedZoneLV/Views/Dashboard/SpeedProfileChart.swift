import Charts
import SwiftUI

/// Full-section speed trace. The chart is intentionally built from recorded
/// samples, not from a simulated curve, so it always reflects what the GPS
/// actually measured.
struct SpeedProfileChart: View {
    let samples: [SpeedSample]
    let officialLimitKmh: Int
    let targetKmh: Int
    let zoneLengthMeters: Double
    var chartHeight: CGFloat = 180
    var showsTitle: Bool = true

    private struct ChartPoint: Identifiable {
        let id: Int
        let kilometers: Double
        let speedKmh: Double
    }

    private var points: [ChartPoint] {
        samples.enumerated().map { index, sample in
            ChartPoint(
                id: index,
                kilometers: sample.distanceMeters / 1_000,
                speedKmh: sample.speedKmh
            )
        }
    }

    private var xMaximum: Double {
        max(zoneLengthMeters / 1_000, points.last?.kilometers ?? 0, 0.1)
    }

    private var yMaximum: Double {
        let observed = points.map(\.speedKmh).max() ?? 0
        return max(observed, Double(max(officialLimitKmh, targetKmh))) + 20
    }

    private var averageSpeed: Double? {
        let speeds = samples.map(\.speedKmh).filter { $0 >= 3 }
        guard !speeds.isEmpty else { return nil }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    private var maximumSpeed: Double? {
        samples.map(\.speedKmh).filter { $0 >= 3 }.max()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsTitle {
                HStack {
                    SectionLabel("Ātruma līkne")
                    Spacer()
                    if let maximumSpeed {
                        Text("MAX \(Fmt.speed(maximumSpeed))")
                            .font(.system(size: 9.5, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Theme.amber)
                    }
                }
            }

            if points.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)

                    Text("Līkne parādīsies, kad būs pirmie mērījuma punkti.")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                Chart {
                    ForEach(points) { point in
                        AreaMark(
                            x: .value("Attālums", point.kilometers),
                            yStart: .value("Ātrums", 0),
                            yEnd: .value("Ātrums", point.speedKmh)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.mint.opacity(0.30), Theme.mint.opacity(0.015)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Attālums", point.kilometers),
                            y: .value("Ātrums", point.speedKmh)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(Theme.mint)
                    }

                    RuleMark(y: .value("Oficiālais limits", Double(officialLimitKmh)))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Theme.red.opacity(0.85))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Limits \(officialLimitKmh)")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundStyle(Theme.red.opacity(0.9))
                        }

                    if targetKmh != officialLimitKmh {
                        RuleMark(y: .value("Mērķis", Double(targetKmh)))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
                            .foregroundStyle(Theme.amber.opacity(0.9))
                            .annotation(position: .bottom, alignment: .leading) {
                                Text("Mērķis \(targetKmh)")
                                    .font(.system(size: 8.5, weight: .bold))
                                    .foregroundStyle(Theme.amber)
                            }
                    }
                }
                .chartXScale(domain: 0...max(xMaximum, 0.05))
                .chartYScale(domain: 0...max(yMaximum, 60))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                            .foregroundStyle(Theme.chartGrid)
                        AxisValueLabel {
                            if let kilometers = value.as(Double.self) {
                                Text(axisDistance(kilometers))
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                            .foregroundStyle(Theme.chartGrid)
                        AxisValueLabel {
                            if let speed = value.as(Double.self) {
                                Text("\(Int(speed))")
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .chartPlotStyle { plot in
                    plot
                        .background(Theme.surface.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(height: chartHeight)
            }

            HStack(spacing: 12) {
                legendDot(color: Theme.mint, text: "Ātrums")
                legendDot(color: Theme.red, text: "Oficiālais limits")
                if targetKmh != officialLimitKmh {
                    legendDot(color: Theme.amber, text: "Tavs mērķis")
                }
                Spacer(minLength: 0)
                if let averageSpeed {
                    Text("VID. \(Fmt.speed(averageSpeed))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func axisDistance(_ kilometers: Double) -> String {
        if kilometers >= 1 {
            let text = String(format: "%.1f", kilometers).replacingOccurrences(of: ".", with: ",")
            return "\(text) km"
        }
        return "\(Int((kilometers * 1_000).rounded())) m"
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
