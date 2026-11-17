import Combine
import SwiftUI

// MARK: - Palette

/// A complete colour set for one visual theme. The rest of the app reads the
/// active palette through the `Theme` namespace, so changing a preset updates
/// every screen without duplicating colour constants in each view.
struct ThemePalette {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let surfaceHigh: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accent: Color
    let accentDeep: Color
    let secondary: Color
    let warning: Color
    let danger: Color
    let tertiary: Color
    let stroke: Color
    let strokeStrong: Color

    func replacingAccent(_ color: Color) -> ThemePalette {
        ThemePalette(
            background: background,
            surface: surface,
            surfaceElevated: surfaceElevated,
            surfaceHigh: surfaceHigh,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
            accent: color,
            accentDeep: color.opacity(0.72),
            secondary: secondary,
            warning: warning,
            danger: danger,
            tertiary: tertiary,
            stroke: stroke,
            strokeStrong: strokeStrong
        )
    }
}

// MARK: - Presets

enum ThemePreset: String, CaseIterable, Identifiable, Sendable {
    case midnight
    case ice
    case sunset
    case violet
    case carbon
    case forest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnight: return "Midnight Mint"
        case .ice: return "Ice Blue"
        case .sunset: return "Sunset"
        case .violet: return "Violet Night"
        case .carbon: return "Carbon"
        case .forest: return "Forest"
        }
    }

    var shortDescription: String {
        switch self {
        case .midnight: return "Noklusētais tumšais auto stils"
        case .ice: return "Vēss zils, sportisks"
        case .sunset: return "Silts oranžs, agresīvs"
        case .violet: return "Purpura nakts, premium"
        case .carbon: return "Monohroms, minimāls"
        case .forest: return "Zaļš, nomierinošs"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .midnight:
            return ThemePalette(
                background: Color(hex: 0x05070A),
                surface: Color(hex: 0x0D1117),
                surfaceElevated: Color(hex: 0x121821),
                surfaceHigh: Color(hex: 0x171E28),
                textPrimary: Color(hex: 0xF4F7FB),
                textSecondary: Color(hex: 0x929CAD),
                textTertiary: Color(hex: 0x5F6A7A),
                accent: Color(hex: 0x35E6A4),
                accentDeep: Color(hex: 0x13B57C),
                secondary: Color(hex: 0x6FA8FF),
                warning: Color(hex: 0xFFC24B),
                danger: Color(hex: 0xFF5D63),
                tertiary: Color(hex: 0xA78BFA),
                stroke: Color.white.opacity(0.08),
                strokeStrong: Color.white.opacity(0.14)
            )

        case .ice:
            return ThemePalette(
                background: Color(hex: 0x04070D),
                surface: Color(hex: 0x0B1220),
                surfaceElevated: Color(hex: 0x0F1B2E),
                surfaceHigh: Color(hex: 0x14243B),
                textPrimary: Color(hex: 0xF2F8FF),
                textSecondary: Color(hex: 0x91A8C4),
                textTertiary: Color(hex: 0x5E778F),
                accent: Color(hex: 0x63B3FF),
                accentDeep: Color(hex: 0x2E7BFF),
                secondary: Color(hex: 0x8EE7FF),
                warning: Color(hex: 0xFFD166),
                danger: Color(hex: 0xFF6B7A),
                tertiary: Color(hex: 0xA78BFA),
                stroke: Color.white.opacity(0.09),
                strokeStrong: Color.white.opacity(0.16)
            )

        case .sunset:
            return ThemePalette(
                background: Color(hex: 0x0A0504),
                surface: Color(hex: 0x160C08),
                surfaceElevated: Color(hex: 0x21120B),
                surfaceHigh: Color(hex: 0x2B180F),
                textPrimary: Color(hex: 0xFFF6F0),
                textSecondary: Color(hex: 0xC4A08D),
                textTertiary: Color(hex: 0x8A6A58),
                accent: Color(hex: 0xFF8A4C),
                accentDeep: Color(hex: 0xE05A1A),
                secondary: Color(hex: 0xFFC2A1),
                warning: Color(hex: 0xFFD166),
                danger: Color(hex: 0xFF5D63),
                tertiary: Color(hex: 0xFF6FB5),
                stroke: Color.white.opacity(0.08),
                strokeStrong: Color.white.opacity(0.15)
            )

        case .violet:
            return ThemePalette(
                background: Color(hex: 0x06040C),
                surface: Color(hex: 0x100A1C),
                surfaceElevated: Color(hex: 0x181028),
                surfaceHigh: Color(hex: 0x211635),
                textPrimary: Color(hex: 0xF8F5FF),
                textSecondary: Color(hex: 0xA89AC4),
                textTertiary: Color(hex: 0x74658F),
                accent: Color(hex: 0xB388FF),
                accentDeep: Color(hex: 0x7C4DFF),
                secondary: Color(hex: 0x7DD3FC),
                warning: Color(hex: 0xFFC24B),
                danger: Color(hex: 0xFF5D8F),
                tertiary: Color(hex: 0xF0ABFC),
                stroke: Color.white.opacity(0.09),
                strokeStrong: Color.white.opacity(0.16)
            )

        case .carbon:
            return ThemePalette(
                background: Color(hex: 0x050505),
                surface: Color(hex: 0x0D0D0F),
                surfaceElevated: Color(hex: 0x141417),
                surfaceHigh: Color(hex: 0x1C1C20),
                textPrimary: Color(hex: 0xF5F5F5),
                textSecondary: Color(hex: 0x9A9AA3),
                textTertiary: Color(hex: 0x66666F),
                accent: Color(hex: 0xE5E7EB),
                accentDeep: Color(hex: 0x9CA3AF),
                secondary: Color(hex: 0xA3A3A3),
                warning: Color(hex: 0xFBBF24),
                danger: Color(hex: 0xF87171),
                tertiary: Color(hex: 0xD4D4D8),
                stroke: Color.white.opacity(0.10),
                strokeStrong: Color.white.opacity(0.18)
            )

        case .forest:
            return ThemePalette(
                background: Color(hex: 0x040A07),
                surface: Color(hex: 0x0A1410),
                surfaceElevated: Color(hex: 0x0F1E17),
                surfaceHigh: Color(hex: 0x15281E),
                textPrimary: Color(hex: 0xF1FFF7),
                textSecondary: Color(hex: 0x91B5A1),
                textTertiary: Color(hex: 0x5F7E6D),
                accent: Color(hex: 0x7CE38B),
                accentDeep: Color(hex: 0x22C55E),
                secondary: Color(hex: 0x5EEAD4),
                warning: Color(hex: 0xFDE047),
                danger: Color(hex: 0xFB7185),
                tertiary: Color(hex: 0xC4B5FD),
                stroke: Color.white.opacity(0.08),
                strokeStrong: Color.white.opacity(0.15)
            )
        }
    }
}

// MARK: - Individual choices

enum AccentChoice: String, CaseIterable, Identifiable, Sendable {
    case theme
    case mint
    case ice
    case amber
    case violet
    case red
    case lime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .theme: return "Tēmas"
        case .mint: return "Menta"
        case .ice: return "Ledus"
        case .amber: return "Dzintars"
        case .violet: return "Violets"
        case .red: return "Sarkans"
        case .lime: return "Laims"
        }
    }

    var color: Color? {
        switch self {
        case .theme: return nil
        case .mint: return Color(hex: 0x35E6A4)
        case .ice: return Color(hex: 0x6FA8FF)
        case .amber: return Color(hex: 0xFFC24B)
        case .violet: return Color(hex: 0xA78BFA)
        case .red: return Color(hex: 0xFF5D63)
        case .lime: return Color(hex: 0xC6FF5E)
        }
    }
}

enum BackgroundStyle: String, CaseIterable, Identifiable, Sendable {
    case aurora
    case mesh
    case solid
    case grid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: return "Aurora"
        case .mesh: return "Mesh"
        case .solid: return "Tumšs"
        case .grid: return "Režģis"
        }
    }
}

enum CardStyle: String, CaseIterable, Identifiable, Sendable {
    case glass
    case solid
    case outlined

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass: return "Stikls"
        case .solid: return "Ciets"
        case .outlined: return "Kontūra"
        }
    }
}

enum Density: String, CaseIterable, Identifiable, Sendable {
    case comfortable
    case compact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .comfortable: return "Ērts"
        case .compact: return "Kompakts"
        }
    }

    var screenPadding: CGFloat {
        switch self {
        case .comfortable: return 20
        case .compact: return 14
        }
    }

    var cardPadding: CGFloat {
        switch self {
        case .comfortable: return 18
        case .compact: return 14
        }
    }
}

enum CornerStyle: String, CaseIterable, Identifiable, Sendable {
    case rounded
    case soft
    case sharp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rounded: return "Noapaļots"
        case .soft: return "Mīksts"
        case .sharp: return "Ass"
        }
    }

    var radius: CGFloat {
        switch self {
        case .rounded: return 24
        case .soft: return 18
        case .sharp: return 12
        }
    }
}

// MARK: - Runtime bridge

/// `Theme` is a static namespace used throughout the existing views. This tiny
/// runtime bridge lets those static colours resolve against the user's active
/// appearance settings without rewriting every view.
final class ThemeRuntime {
    static let shared = ThemeRuntime()

    weak var appearance: AppearanceSettings?

    private init() {}

    var palette: ThemePalette {
        appearance?.resolvedPalette ?? ThemePreset.midnight.palette
    }

    var backgroundStyle: BackgroundStyle {
        appearance?.backgroundStyle ?? .aurora
    }

    var cardStyle: CardStyle {
        appearance?.cardStyle ?? .glass
    }

    var density: Density {
        appearance?.density ?? .comfortable
    }

    var cornerStyle: CornerStyle {
        appearance?.cornerStyle ?? .rounded
    }
}

// MARK: - Persisted settings

final class AppearanceSettings: ObservableObject {
    @Published var theme: ThemePreset {
        didSet { persist() }
    }

    @Published var accent: AccentChoice {
        didSet { persist() }
    }

    @Published var backgroundStyle: BackgroundStyle {
        didSet { persist() }
    }

    @Published var cardStyle: CardStyle {
        didSet { persist() }
    }

    @Published var density: Density {
        didSet { persist() }
    }

    @Published var cornerStyle: CornerStyle {
        didSet { persist() }
    }

    /// Individual dashboard elements. Turning one off removes it from the
    /// dashboard without disabling the underlying detection or measurement.
    @Published var showsSpeedGauge: Bool {
        didSet { persist() }
    }

    @Published var showsSpeedCurve: Bool {
        didSet { persist() }
    }

    @Published var showsAverageCard: Bool {
        didSet { persist() }
    }

    @Published var showsMetricsGrid: Bool {
        didSet { persist() }
    }

    @Published var showsProgressCard: Bool {
        didSet { persist() }
    }

    @Published var showsApproachDetails: Bool {
        didSet { persist() }
    }

    @Published var showsOnboarding: Bool {
        didSet { persist() }
    }

    @Published var showsDisclaimer: Bool {
        didSet { persist() }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let theme = "appearance.theme"
        static let accent = "appearance.accent"
        static let background = "appearance.background"
        static let card = "appearance.card"
        static let density = "appearance.density"
        static let corner = "appearance.corner"
        static let gauge = "appearance.showGauge"
        static let curve = "appearance.showCurve"
        static let average = "appearance.showAverage"
        static let metrics = "appearance.showMetrics"
        static let progress = "appearance.showProgress"
        static let approach = "appearance.showApproach"
        static let onboarding = "appearance.showOnboarding"
        static let disclaimer = "appearance.showDisclaimer"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.theme = ThemePreset(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .midnight
        self.accent = AccentChoice(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .theme
        self.backgroundStyle = BackgroundStyle(rawValue: defaults.string(forKey: Keys.background) ?? "") ?? .aurora
        self.cardStyle = CardStyle(rawValue: defaults.string(forKey: Keys.card) ?? "") ?? .glass
        self.density = Density(rawValue: defaults.string(forKey: Keys.density) ?? "") ?? .comfortable
        self.cornerStyle = CornerStyle(rawValue: defaults.string(forKey: Keys.corner) ?? "") ?? .rounded

        self.showsSpeedGauge = defaults.object(forKey: Keys.gauge) as? Bool ?? true
        self.showsSpeedCurve = defaults.object(forKey: Keys.curve) as? Bool ?? true
        self.showsAverageCard = defaults.object(forKey: Keys.average) as? Bool ?? true
        self.showsMetricsGrid = defaults.object(forKey: Keys.metrics) as? Bool ?? true
        self.showsProgressCard = defaults.object(forKey: Keys.progress) as? Bool ?? true
        self.showsApproachDetails = defaults.object(forKey: Keys.approach) as? Bool ?? true
        self.showsOnboarding = defaults.object(forKey: Keys.onboarding) as? Bool ?? true
        self.showsDisclaimer = defaults.object(forKey: Keys.disclaimer) as? Bool ?? true

        ThemeRuntime.shared.appearance = self
    }

    var resolvedPalette: ThemePalette {
        let base = theme.palette
        guard let custom = accent.color else { return base }
        return base.replacingAccent(custom)
    }

    func resetToDefaults() {
        theme = .midnight
        accent = .theme
        backgroundStyle = .aurora
        cardStyle = .glass
        density = .comfortable
        cornerStyle = .rounded
        showsSpeedGauge = true
        showsSpeedCurve = true
        showsAverageCard = true
        showsMetricsGrid = true
        showsProgressCard = true
        showsApproachDetails = true
        showsOnboarding = true
        showsDisclaimer = true
    }

    private func persist() {
        defaults.set(theme.rawValue, forKey: Keys.theme)
        defaults.set(accent.rawValue, forKey: Keys.accent)
        defaults.set(backgroundStyle.rawValue, forKey: Keys.background)
        defaults.set(cardStyle.rawValue, forKey: Keys.card)
        defaults.set(density.rawValue, forKey: Keys.density)
        defaults.set(cornerStyle.rawValue, forKey: Keys.corner)
        defaults.set(showsSpeedGauge, forKey: Keys.gauge)
        defaults.set(showsSpeedCurve, forKey: Keys.curve)
        defaults.set(showsAverageCard, forKey: Keys.average)
        defaults.set(showsMetricsGrid, forKey: Keys.metrics)
        defaults.set(showsProgressCard, forKey: Keys.progress)
        defaults.set(showsApproachDetails, forKey: Keys.approach)
        defaults.set(showsOnboarding, forKey: Keys.onboarding)
        defaults.set(showsDisclaimer, forKey: Keys.disclaimer)
    }
}
