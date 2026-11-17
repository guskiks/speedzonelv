import SwiftUI

enum Theme {
    // The active palette is resolved through AppearanceSettings. Every view
    // continues to use the same `Theme.mint` / `Theme.textPrimary` names.
    static var palette: ThemePalette { ThemeRuntime.shared.palette }

    // Base surfaces
    static var background: Color { palette.background }
    static var surface: Color { palette.surface }
    static var surfaceElevated: Color { palette.surfaceElevated }
    static var surfaceHigh: Color { palette.surfaceHigh }

    // Text
    static var textPrimary: Color { palette.textPrimary }
    static var textSecondary: Color { palette.textSecondary }
    static var textTertiary: Color { palette.textTertiary }

    // Accents (historical names are kept so existing views stay readable)
    static var mint: Color { palette.accent }
    static var mintDeep: Color { palette.accentDeep }
    static var ice: Color { palette.secondary }
    static var amber: Color { palette.warning }
    static var red: Color { palette.danger }
    static var violet: Color { palette.tertiary }

    // Lines
    static var stroke: Color { palette.stroke }
    static var strokeStrong: Color { palette.strokeStrong }
    static var chartGrid: Color { palette.stroke }

    // Paddings and styling
    static var screenPadding: CGFloat { ThemeRuntime.shared.density.screenPadding }
    static var cardPadding: CGFloat { ThemeRuntime.shared.density.cardPadding }
    static var cardRadius: CGFloat { ThemeRuntime.shared.cornerStyle.radius }
    static var backgroundStyle: BackgroundStyle { ThemeRuntime.shared.backgroundStyle }
    static var cardStyle: CardStyle { ThemeRuntime.shared.cardStyle }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension SpeedBand {
    var tint: Color {
        switch self {
        case .unknown: return Theme.ice
        case .safe: return Theme.mint
        case .nearLimit: return Theme.amber
        case .overLimit: return Theme.red
        }
    }

    var symbol: String {
        switch self {
        case .unknown: return "questionmark"
        case .safe: return "checkmark"
        case .nearLimit: return "exclamationmark"
        case .overLimit: return "exclamationmark.triangle.fill"
        }
    }
}

struct AppBackground: View {
    var body: some View {
        switch Theme.backgroundStyle {
        case .aurora:
            aurora
        case .mesh:
            mesh
        case .solid:
            solid
        case .grid:
            grid
        }
    }

    private var aurora: some View {
        ZStack {
            Theme.background

            RadialGradient(
                colors: [Theme.mint.opacity(0.13), .clear],
                center: UnitPoint(x: 0.12, y: -0.02),
                startRadius: 10,
                endRadius: 450
            )

            RadialGradient(
                colors: [Theme.ice.opacity(0.08), .clear],
                center: UnitPoint(x: 0.95, y: 0.38),
                startRadius: 10,
                endRadius: 380
            )

            LinearGradient(
                colors: [.clear, Theme.background.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var mesh: some View {
        ZStack {
            Theme.background

            RadialGradient(
                colors: [Theme.violet.opacity(0.18), .clear],
                center: UnitPoint(x: 0.08, y: 0.02),
                startRadius: 20,
                endRadius: 430
            )

            RadialGradient(
                colors: [Theme.mint.opacity(0.14), .clear],
                center: UnitPoint(x: 0.98, y: 0.22),
                startRadius: 10,
                endRadius: 390
            )

            RadialGradient(
                colors: [Theme.ice.opacity(0.10), .clear],
                center: UnitPoint(x: 0.55, y: 1.02),
                startRadius: 10,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }

    private var solid: some View {
        ZStack {
            Theme.background

            LinearGradient(
                colors: [Theme.surfaceElevated.opacity(0.55), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    private var grid: some View {
        ZStack {
            Theme.background

            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 30
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }
                context.stroke(path, with: .color(Theme.stroke), lineWidth: 0.5)
            }

            RadialGradient(
                colors: [Theme.mint.opacity(0.12), .clear],
                center: UnitPoint(x: 0.2, y: 0.0),
                startRadius: 10,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}
