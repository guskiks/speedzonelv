import SwiftUI

struct SpeedGaugeView: View {
    let speedKmh: Double
    let limitKmh: Int?
    let targetKmh: Int?
    let accuracyMeters: Double?
    let isIdle: Bool
    var compact: Bool = false

    private var effectiveTarget: Int? {
        targetKmh ?? limitKmh
    }

    private var band: SpeedBand {
        guard let effectiveTarget else { return .unknown }
        return SpeedBand(speedKmh: speedKmh, limitKmh: effectiveTarget)
    }

    private var gaugeMaximum: Double {
        max(140, Double(effectiveTarget ?? 140) + 50)
    }

    private var progress: Double {
        min(max(speedKmh / gaugeMaximum, 0), 1)
    }

    private var accuracyText: String {
        guard let accuracyMeters else { return "GPS —" }
        return "GPS ±\(Int(accuracyMeters.rounded())) m"
    }

    private var limitText: String {
        guard let limitKmh else { return "—" }
        return Fmt.speedLimit(limitKmh)
    }

    private var targetText: String? {
        guard let targetKmh, targetKmh != limitKmh else { return nil }
        return Fmt.speedLimit(targetKmh)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel("Pašreizējais ātrums")

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8, weight: .semibold))
                    Text(accuracyText)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Theme.textTertiary)
            }

            ZStack {
                ForEach(0..<9, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.16 : 0.07))
                        .frame(width: 1.5, height: index.isMultiple(of: 2) ? 8 : 4)
                        .offset(y: compact ? -94 : -123)
                        .rotationEffect(.degrees(-135 + 270 * Double(index) / 8))
                }

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        Color.white.opacity(0.055),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                     .padding(compact ? 18 : 24)

                Circle()
                    .trim(from: 0, to: 0.75 * progress)
                    .stroke(
                        LinearGradient(
                            colors: [band.tint.opacity(0.35), band.tint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                     .padding(compact ? 18 : 24)
                    .shadow(color: band.tint.opacity(0.45), radius: 12)
                    .animation(.easeOut(duration: 0.3), value: progress)

                VStack(spacing: 0) {
                    Text(Fmt.speedRounded(speedKmh))
                         .font(.system(size: compact ? 58 : 76, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: speedKmh))
                        .animation(.easeOut(duration: 0.28), value: speedKmh)

                    Text("km/h")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.6)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: compact ? 210 : 270, height: compact ? 210 : 270)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pašreizējais ātrums")
            .accessibilityValue("\(Fmt.speedRounded(speedKmh)) kilometri stundā")

            HStack(spacing: 8) {
                StatusPill(
                    text: isIdle ? "Gaidīšana" : band.label,
                    color: isIdle ? Theme.textTertiary : band.tint
                )

                Spacer()

                if let targetText {
                    HStack(spacing: 5) {
                        Text("MĒRĶIS")
                            .font(.system(size: 8.5, weight: .bold))
                            .tracking(1.0)
                        Text(targetText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(Theme.amber)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background {
                        Capsule().fill(Theme.amber.opacity(0.10))
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 10, weight: .semibold))

                    Text("LIMITS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.1)

                    Text(limitText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.045))
                        .overlay {
                            Capsule().stroke(Theme.stroke, lineWidth: 1)
                        }
                }
            }
        }
        .dashboardCard(padding: compact ? 10 : nil)
    }
}
