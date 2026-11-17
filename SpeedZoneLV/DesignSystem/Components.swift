import SwiftUI

struct DashboardCardModifier: ViewModifier {
    var padding: CGFloat?
    var radius: CGFloat?

    func body(content: Content) -> some View {
        let resolvedPadding = padding ?? Theme.cardPadding
        let resolvedRadius = radius ?? Theme.cardRadius

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(resolvedPadding)
            .background { cardBackground(radius: resolvedRadius) }
            .shadow(
                color: Color.black.opacity(Theme.cardStyle == .outlined ? 0.20 : 0.38),
                radius: Theme.cardStyle == .outlined ? 12 : 22,
                x: 0,
                y: Theme.cardStyle == .outlined ? 7 : 14
            )
    }

    @ViewBuilder
    private func cardBackground(radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        switch Theme.cardStyle {
        case .glass:
            shape
                .fill(
                    LinearGradient(
                        colors: [Theme.surfaceElevated, Theme.surface.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.11), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }

        case .solid:
            shape
                .fill(Theme.surfaceElevated)
                .overlay {
                    shape.strokeBorder(Theme.stroke, lineWidth: 1)
                }

        case .outlined:
            shape
                .fill(Theme.surface.opacity(0.55))
                .overlay {
                    shape.strokeBorder(Theme.strokeStrong, lineWidth: 1.2)
                }
        }
    }
}

extension View {
    func dashboardCard(padding: CGFloat? = nil, radius: CGFloat? = nil) -> some View {
        modifier(DashboardCardModifier(padding: padding, radius: radius))
    }
}

struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.7)
            .foregroundStyle(Theme.textTertiary)
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    var showsDot: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if showsDot {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .shadow(color: color.opacity(0.9), radius: 4)
            }
            Text(text.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(color.opacity(0.11))
                .overlay {
                    Capsule().stroke(color.opacity(0.20), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

struct MetricTile: View {
    let icon: String
    let label: String
    let value: String
    var unit: String? = nil
    var accent: Color = Theme.ice

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 26, height: 26)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accent.opacity(0.12))
                    }
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let unit {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: max(Theme.cardRadius - 4, 10), style: .continuous)
                .fill(Theme.surfaceElevated.opacity(0.86))
                .overlay {
                    RoundedRectangle(cornerRadius: max(Theme.cardRadius - 4, 10), style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.mint

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color(hex: 0x03130D))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                    }
            }
            .shadow(color: tint.opacity(0.22), radius: 18, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.045))
                    .overlay {
                        Capsule().stroke(Theme.strokeStrong, lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: configuration.isPressed)
    }
}
