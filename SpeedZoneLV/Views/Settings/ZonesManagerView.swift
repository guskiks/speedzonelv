import SwiftUI
import UniformTypeIdentifiers

/// Lists, edits and deletes locally added zones. Official LVC sections can be
/// started from a template, but the template contains only the published
/// kilometre range — the user must supply the real coordinates.
struct ZonesManagerView: View {
    @Environment(AppEnvironment.self) private var app
    @EnvironmentObject private var userZones: UserZoneStore
    @Environment(\.dismiss) private var dismiss

    @State private var editorContext: ZoneEditorContext?
    @State private var showsTemplatePicker = false
    @State private var pendingTemplate: ZoneTemplate?
    @State private var showsImporter = false
    @State private var showsDeleteAllConfirmation = false
    @State private var importSummary: UserZoneStore.ImportSummary?
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        introCard
                        addCard
                        zonesCard
                        if importSummary != nil || importError != nil {
                            importResultCard
                        }
                        DisclaimerFooter(
                            text: "Manuāli pievienotās zonas ir tikai tavi lokāli dati. Pārbaudi ceļa zīmes un oficiālos avotus pirms paļaujies uz mērījumu."
                        )
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Manas zonas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aizvērt") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .sheet(item: $editorContext) { context in
                ZoneEditorView(zone: context.zone, template: context.template)
                    .environment(app)
                    .environmentObject(app.userZones)
            }
            .sheet(isPresented: $showsTemplatePicker, onDismiss: {
                if let template = pendingTemplate {
                    pendingTemplate = nil
                    editorContext = ZoneEditorContext(zone: nil, template: template)
                }
            }) {
                ZoneTemplatePicker { template in
                    pendingTemplate = template
                    showsTemplatePicker = false
                }
                .environment(app)
            }
            .fileImporter(
                isPresented: $showsImporter,
                allowedContentTypes: [.json, .text],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .confirmationDialog(
                "Dzēst visas manuālās zonas?",
                isPresented: $showsDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Dzēst visas", role: .destructive) {
                    userZones.removeAll()
                    app.refreshZones()
                }
                Button("Atcelt", role: .cancel) {}
            } message: {
                Text("Šī darbība neatgriezeniski izdzēsīs visas lokāli pievienotās zonas. Vēsture netiks dzēsta.")
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.violet)

                Text("Manuālā zonu pārvaldība")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("Pievieno savu kontrolposmu ar precīzām sākuma un finiša koordinātām. Zonas glabājas tikai šajā ierīcē un netiek augšupielādētas.")
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dashboardCard()
    }

    private var addCard: some View {
        VStack(spacing: 10) {
            Button {
                editorContext = ZoneEditorContext(zone: nil, template: nil)
            } label: {
                Label("Pievienot zonu manuāli", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                showsTemplatePicker = true
            } label: {
                Label("Sākt no oficiāla LVC šablona", systemImage: "list.bullet.rectangle")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                showsImporter = true
            } label: {
                Label("Importēt JSON failu", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .dashboardCard()
    }

    private var zonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Manuālās zonas")
                Spacer()
                Text("\(userZones.zones.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.mint)
            }

            if userZones.zones.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)

                    Text("Vēl nav pievienotu zonu. Sāc ar tukšu formu vai izvēlies oficiālu kilometru diapazonu.")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(userZones.zones) { zone in
                    ZoneRow(
                        zone: zone,
                        onEdit: {
                            editorContext = ZoneEditorContext(zone: zone, template: nil)
                        },
                        onDelete: {
                            userZones.delete(zone)
                            app.refreshZones()
                        }
                    )

                    if zone.id != userZones.zones.last?.id {
                        Rectangle()
                            .fill(Theme.stroke)
                            .frame(height: 1)
                    }
                }

                Button(role: .destructive) {
                    showsDeleteAllConfirmation = true
                } label: {
                    Label("Dzēst visas manuālās zonas", systemImage: "trash")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            if let error = userZones.lastError {
                Text(error)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .dashboardCard()
    }

    private var importResultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Importa rezultāts")

            if let importSummary {
                Text("Importētas \(importSummary.imported), izlaistas \(importSummary.skipped).")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(importSummary.skipped == 0 ? Theme.mint : Theme.amber)

                if !importSummary.errors.isEmpty {
                    ForEach(Array(importSummary.errors.prefix(6).indices), id: \.self) { index in
                        Text("• \(importSummary.errors[index])")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let importError {
                Text(importError)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Notīrīt ziņojumu") {
                importSummary = nil
                importError = nil
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.mint)
        }
        .dashboardCard()
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        importSummary = nil
        importError = nil

        do {
            let urls = try result.get()
            guard let url = urls.first else { return }

            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let summary = userZones.importJSON(data: data)
            importSummary = summary
            app.refreshZones()
        } catch {
            importError = "Failu neizdevās nolasīt: \(error.localizedDescription)"
        }
    }
}

// MARK: - Row

private struct ZoneRow: View {
    let zone: SpeedZone
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(zone.road)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule().fill(Color.white.opacity(0.055))
                    }

                Text(zone.verification.label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(zone.verification == .verified ? Theme.mint : Theme.amber)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.ice)
                        .frame(width: 30, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rediģēt zonu")

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Dzēst", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 30, height: 28)
                        .contentShape(Rectangle())
                }
            }

            Text(zone.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)

            HStack(spacing: 10) {
                Label(Fmt.distance(zone.officialLengthMeters), systemImage: "ruler")
                Label(Fmt.speedLimit(zone.speedLimitKmh), systemImage: "speedometer")
                Label(zone.directionLabel, systemImage: "arrow.up.right")
            }
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)

            Text("\(String(format: "%.5f", zone.start.latitude)), \(String(format: "%.5f", zone.start.longitude)) → \(String(format: "%.5f", zone.end.latitude)), \(String(format: "%.5f", zone.end.longitude))")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Template picker

private struct ZoneTemplatePicker: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (ZoneTemplate) -> Void

    @State private var query = ""

    private var filtered: [ZoneTemplate] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ZoneCatalog.officialTemplates }
        return ZoneCatalog.officialTemplates.filter { template in
            template.road.localizedCaseInsensitiveContains(trimmed)
                || template.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 12) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.amber)
                                .padding(.top, 1)

                            Text("Šie ir oficiāli publicētie kilometru diapazoni. Tajos nav koordinātu, tāpēc pēc šablona izvēles būs jāievada reālais posma sākums un finišs.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.amber.opacity(0.08))
                        }

                        ForEach(filtered) { template in
                            Button {
                                onSelect(template)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(template.road)
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(0.7)
                                            .foregroundStyle(Theme.mint)

                                        Spacer()

                                        Text(template.rangeText)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(Theme.textTertiary)
                                    }

                                    Text(template.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                        .multilineTextAlignment(.leading)

                                    Text(template.note)
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundStyle(Theme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Theme.surfaceElevated)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Theme.stroke, lineWidth: 1)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
                .searchable(text: $query, prompt: "Meklēt ceļu vai posmu")
            }
            .navigationTitle("Oficiālie šabloni")
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
}
