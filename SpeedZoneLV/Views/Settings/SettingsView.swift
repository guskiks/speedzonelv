import CoreLocation
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var app
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var appearance: AppearanceSettings
    @EnvironmentObject private var userZones: UserZoneStore
    @Environment(\.openURL) private var openURL

    @State private var showsZonesManager = false
    @State private var showsResetAppearanceConfirmation = false

    private var database: ZoneDatabase {
        app.zoneRepository.database
    }

    private var versionText: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(
                    title: "Iestatījumi",
                    subtitle: "Braukšana, izskats, zonas un atļaujas."
                )

                drivingCard
                personalTargetCard
                appearanceCard
                elementsCard
                permissionsCard
                zonesCard
                aboutCard

                DisclaimerFooter()
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 10)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showsZonesManager) {
            ZonesManagerView()
                .environment(app)
                .environmentObject(app.userZones)
        }
        .onAppear {
            app.dashboard.location.refreshAuthorizationStatus()
            Task { @MainActor in
                await app.notifications.refreshAuthorizationStatus()
            }
        }
    }

    // MARK: - Driving

    private var drivingCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionLabel("Braukšana un fons")

            toggleRow(
                title: "Automātiski sākt GPS",
                detail: "Atverot lietotni un esot atļaujai, sekošana sākas pati",
                isOn: $settings.autoStartEnabled
            )

            divider

            toggleRow(
                title: "Fona izsekošana",
                detail: "Turpina mērīt ar izslēgtu ekrānu (prasa “Vienmēr” atļauju)",
                isOn: $settings.backgroundTrackingEnabled
            )

            divider

            toggleRow(
                title: "Automātiska zonu noteikšana",
                detail: "Pats sāk mērījumu, tuvojoties zonai pareizajā virzienā",
                isOn: $settings.autoDetectionEnabled
            )

            divider

            toggleRow(
                title: "Automātiski turēt ekrānu ieslēgtu",
                detail: "Tikai aktīva mērījuma laikā",
                isOn: $settings.keepScreenAwakeDuringRide
            )

            divider

            toggleRow(
                title: "Haptiskā atgriezeniskā saite",
                detail: "Īsi vibrācijas signāli par sākumu, mērķi un finišu",
                isOn: $settings.hapticsEnabled
            )

            divider

            toggleRow(
                title: "Live Activity / Dynamic Island",
                detail: liveActivityDetail,
                isOn: $settings.liveActivitiesEnabled
            )

            if settings.backgroundTrackingEnabled {
                infoNote(
                    "Fona mērījums strādā tikai ar atrašanās vietas atļauju “Vienmēr”. Ja tā nav piešķirta, brauciens turpināsies, kamēr lietotne ir priekšplānā.",
                    tint: Theme.amber
                )
            }

            Button {
                app.dashboard.startDemo()
            } label: {
                Label("Palaist demo režīmu", systemImage: "play.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .dashboardCard()
    }

    private var liveActivityDetail: String {
        if !app.liveActivity.isSystemEnabled {
            return "Sistēmā izslēgta · pārbaudi iPhone iestatījumus"
        }
        if app.liveActivity.isActive {
            return "Aktīva · rāda ātrumu slēdzenes ekrānā"
        }
        return "Rāda mērījumu slēdzenes ekrānā un Dynamic Island"
    }

    // MARK: - Personal target

    private var personalTargetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Personīgais mērķis")
                Spacer()
                Text("+\(settings.personalTargetOffsetKmh) km/h")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.amber)
            }

            Text("Tu vari uzstādīt savu mērķi virs oficiālā limita. Oficiālais limits vienmēr paliek redzams un netiek mainīts — mērķis ir tikai tava personīgā atsauce.")
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Slider(
                value: Binding(
                    get: { Double(settings.personalTargetOffsetKmh) },
                    set: { settings.personalTargetOffsetKmh = Int($0.rounded()) }
                ),
                in: 0...20,
                step: 1
            )
            .tint(Theme.amber)

            HStack {
                Text("0 km/h")
                Spacer()
                Text("+20 km/h")
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Theme.textTertiary)

            HStack(spacing: 10) {
                targetPreview(title: "Oficiālais", value: "90", tint: Theme.textSecondary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                targetPreview(
                    title: "Tavs mērķis",
                    value: "\(90 + settings.personalTargetOffsetKmh)",
                    tint: Theme.amber
                )
                Spacer(minLength: 0)
            }
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            }

            Text("Piemērs ar 90 km/h zonu. \(settings.personalTargetDescription)")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            infoNote(
                "Personīgais mērķis nepadara braukšanu virs oficiālā limita atļautu. Ceļa zīmes un noteikumi ir noteicošie.",
                tint: Theme.red
            )
        }
        .dashboardCard()
    }

    private func targetPreview(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Theme.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tint)
                Text("km/h")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Izskats")

            Text("Izvēlies gatavu stilu. Pēc tam vari mainīt akcentu, fonu, kartītes, blīvumu un stūrus atsevišķi.")
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(ThemePreset.allCases) { preset in
                    ThemePresetCell(
                        preset: preset,
                        isSelected: appearance.theme == preset
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            appearance.theme = preset
                        }
                    }
                }
            }

            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 8) {
                Text("AKCENTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AccentChoice.allCases) { choice in
                            AccentChoiceCell(
                                choice: choice,
                                isSelected: appearance.accent == choice
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    appearance.accent = choice
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            styleRow(
                title: "Fons",
                selection: $appearance.backgroundStyle,
                options: BackgroundStyle.allCases,
                label: { $0.title }
            )

            styleRow(
                title: "Kartītes",
                selection: $appearance.cardStyle,
                options: CardStyle.allCases,
                label: { $0.title }
            )

            styleRow(
                title: "Blīvums",
                selection: $appearance.density,
                options: Density.allCases,
                label: { $0.title }
            )

            styleRow(
                title: "Stūri",
                selection: $appearance.cornerStyle,
                options: CornerStyle.allCases,
                label: { $0.title }
            )

            Button {
                showsResetAppearanceConfirmation = true
            } label: {
                Label("Atjaunot izskata iestatījumus", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(SecondaryButtonStyle())
            .confirmationDialog(
                "Atjaunot izskatu?",
                isPresented: $showsResetAppearanceConfirmation,
                titleVisibility: .visible
            ) {
                Button("Atjaunot", role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appearance.resetToDefaults()
                    }
                }
                Button("Atcelt", role: .cancel) {}
            } message: {
                Text("Tēma, akcents, fons, kartītes un visi elementu slēdži atgriezīsies sākotnējā stāvoklī.")
            }
        }
        .dashboardCard()
    }

    private func styleRow<Option: Identifiable & Hashable>(
        title: String,
        selection: Binding<Option>,
        options: [Option],
        label: @escaping (Option) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)

            Picker(title, selection: selection) {
                ForEach(options) { option in
                    Text(label(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Elements

    private var elementsCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionLabel("Ekrāna elementi")

            Text("Ieslēdz vai izslēdz atsevišķus dashboard elementus. Mērījums un zonu noteikšana darbojas neatkarīgi no šiem slēdžiem.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            toggleRow(
                title: "Ātruma mērinstruments",
                detail: "Lielais pašreizējā ātruma rādītājs",
                isOn: $appearance.showsSpeedGauge
            )

            divider

            toggleRow(
                title: "Pilna ātruma līkne",
                detail: "Grafiks visam posmam ar limitu un mērķi",
                isOn: $appearance.showsSpeedCurve
            )

            divider

            toggleRow(
                title: "Vidējā ātruma kartīte",
                detail: "Vidējais, prognoze un ieteikums",
                isOn: $appearance.showsAverageCard
            )

            divider

            toggleRow(
                title: "Mērījumu režģis",
                detail: "Sākuma ātrums, laiks, atlikušais attālums",
                isOn: $appearance.showsMetricsGrid
            )

            divider

            toggleRow(
                title: "Posma gaitas josla",
                detail: "Progresa josla un nobrauktais attālums",
                isOn: $appearance.showsProgressCard
            )

            divider

            toggleRow(
                title: "Tuvošanās detaļas",
                detail: "Attālums līdz zonai pirms iebraukšanas",
                isOn: $appearance.showsApproachDetails
            )

            divider

            toggleRow(
                title: "Aktivizācijas soļi",
                detail: "“Kā tas strādā” kartīte tukšajā ekrānā",
                isOn: $appearance.showsOnboarding
            )

            divider

            toggleRow(
                title: "Juridiskais paziņojums",
                detail: "Informatīvā atruna ekrāna apakšā",
                isOn: $appearance.showsDisclaimer
            )
        }
        .dashboardCard()
    }

    // MARK: - Permissions

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionLabel("Atļaujas")

            permissionRow(
                icon: "location.fill",
                title: "Atrašanās vieta",
                status: locationStatusText,
                tint: locationStatusColor
            )

            permissionRow(
                icon: "bell.badge.fill",
                title: "Paziņojumi",
                status: notificationStatusText,
                tint: notificationStatusColor
            )

            Toggle(isOn: $settings.notificationsEnabled) {
                settingsLabel(
                    title: "Paziņojumi par zonām",
                    detail: "Tuvošanās, iebraukšana, mērķis un finišs"
                )
            }
            .tint(Theme.mint)

            Toggle(isOn: $settings.soundAlertsEnabled) {
                settingsLabel(
                    title: "Skaņas signāli",
                    detail: "Paziņojumiem pievieno skaņu"
                )
            }
            .tint(Theme.mint)

            HStack(spacing: 10) {
                if locationStatus == .notDetermined {
                    Button {
                        app.dashboard.requestLocationPermission()
                    } label: {
                        Label("Atļaut atrašanās vietu", systemImage: "location.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else if locationStatus == .authorizedWhenInUse {
                    Button {
                        app.dashboard.requestAlwaysPermission()
                    } label: {
                        Label("Mainīt uz “Vienmēr”", systemImage: "location.fill.viewfinder")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if notificationStatus == .notDetermined {
                    Button {
                        Task { @MainActor in
                            await app.notifications.requestAuthorization()
                        }
                    } label: {
                        Label("Atļaut paziņojumus", systemImage: "bell.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }

            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            } label: {
                Label("Atvērt sistēmas iestatījumus", systemImage: "gearshape")
            }
            .buttonStyle(SecondaryButtonStyle())

            Text("Lai mērītu ar izslēgtu ekrānu, sistēmā jāatļauj atrašanās vieta “Vienmēr”.")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dashboardCard()
    }

    // MARK: - Zones

    private var zonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Zonas un datubāze")

            InfoRow(
                icon: "checkmark.shield.fill",
                title: "Pārbaudītas datubāzē",
                value: "\(database.verifiedZones.count)",
                tint: Theme.mint
            )

            InfoRow(
                icon: "square.and.pencil",
                title: "Manuāli pievienotas",
                value: "\(userZones.zones.count)",
                tint: Theme.violet
            )

            InfoRow(
                icon: "calendar",
                title: "Datubāze atjaunināta",
                value: database.updatedAt,
                tint: Theme.ice
            )

            InfoRow(
                icon: "externaldrive.fill",
                title: "Avots",
                value: database.origin,
                tint: Theme.violet
            )

            Text(database.disclaimer)
                .font(.system(size: 10.5, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let error = database.loadError {
                Text(error)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !database.sources.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("AVOTI")
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Theme.textTertiary)

                    ForEach(database.sources, id: \.self) { source in
                        Text(source.name)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Button {
                showsZonesManager = true
            } label: {
                Label("Pārvaldīt manās zonas", systemImage: "square.and.pencil")
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))

            Button {
                app.reloadDatabase()
            } label: {
                Label("Pārlādēt datubāzi", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryButtonStyle())

            Text("Datubāzi var atjaunināt bez lietotnes pārbūves, ievietojot jaunu zones_lv.json lietotnes dokumentu mapē.")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dashboardCard()
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Par lietotni")

            InfoRow(icon: "info.circle", title: "Versija", value: versionText, tint: Theme.ice)
            InfoRow(icon: "iphone", title: "Mērķa ierīce", value: "iPhone 14 Pro+", tint: Theme.mint)
            InfoRow(icon: "lock.shield.fill", title: "Datu glabāšana", value: "Tikai šajā ierīcē", tint: Theme.violet)

            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 1)

            Text("SpeedZone LV ir privāta palīglietotne. Tā neaizstāj oficiālo vidējā ātruma kontroles sistēmu un nesniedz juridisku mērījumu.")
                .font(.system(size: 10.5, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dashboardCard()
    }

    // MARK: - Small components

    private var divider: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(height: 1)
    }

    private func toggleRow(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            settingsLabel(title: title, detail: detail)
        }
        .tint(Theme.mint)
    }

    private func settingsLabel(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Text(detail)
                .font(.system(size: 10.5, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func infoNote(_ text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "info.circle")
                .font(.system(size: 10, weight: .semibold))
                .padding(.top, 1)

            Text(text)
                .font(.system(size: 10.5, weight: .regular))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .foregroundStyle(tint)
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.08))
        }
    }

    private func permissionRow(icon: String, title: String, status: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.11))
                }

            Text(title)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 8)

            Text(status)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
        }
    }

    private var locationStatus: CLAuthorizationStatus {
        app.dashboard.location.authorizationStatus
    }

    private var locationStatusText: String {
        switch locationStatus {
        case .notDetermined: return "Nav pieprasīta"
        case .restricted: return "Ierobežota"
        case .denied: return "Aizliegta"
        case .authorizedWhenInUse: return "Kamēr lietotnē"
        case .authorizedAlways: return "Vienmēr"
        @unknown default: return "Nezināma"
        }
    }

    private var locationStatusColor: Color {
        switch locationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return Theme.mint
        case .denied, .restricted: return Theme.red
        case .notDetermined: return Theme.amber
        @unknown default: return Theme.textTertiary
        }
    }

    private var notificationStatus: UNAuthorizationStatus {
        app.notifications.authorizationStatus
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .notDetermined: return "Nav pieprasīta"
        case .denied: return "Aizliegta"
        case .authorized: return "Atļauta"
        case .provisional: return "Provizoriska"
        case .ephemeral: return "Īslaicīga"
        @unknown default: return "Nezināma"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return Theme.mint
        case .denied: return Theme.red
        case .notDetermined: return Theme.amber
        @unknown default: return Theme.textTertiary
        }
    }
}

// MARK: - Theme cells

private struct ThemePresetCell: View {
    let preset: ThemePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [preset.palette.surfaceElevated, preset.palette.background],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 54)
                        .overlay(alignment: .bottomLeading) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(preset.palette.accent)
                                    .frame(width: 10, height: 10)
                                Capsule()
                                    .fill(preset.palette.textPrimary.opacity(0.65))
                                    .frame(width: 22, height: 4)
                                Capsule()
                                    .fill(preset.palette.textSecondary.opacity(0.45))
                                    .frame(width: 14, height: 4)
                            }
                            .padding(9)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.stroke, lineWidth: 1)
                        }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(preset.palette.accent)
                            .padding(6)
                    }
                }

                Text(preset.title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(preset.shortDescription)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            .padding(9)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isSelected ? preset.palette.accent.opacity(0.10) : Color.white.opacity(0.035))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(isSelected ? preset.palette.accent.opacity(0.65) : Theme.stroke, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AccentChoiceCell: View {
    let choice: AccentChoice
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(choice.color ?? Theme.mint)
                        .frame(width: 28, height: 28)

                    if choice == .theme {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.65))
                    }

                    if isSelected {
                        Circle()
                            .stroke(Theme.textPrimary, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                }
                .frame(width: 38, height: 38)

                Text(choice.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textTertiary)
            }
            .frame(minWidth: 52)
        }
        .buttonStyle(.plain)
    }
}
