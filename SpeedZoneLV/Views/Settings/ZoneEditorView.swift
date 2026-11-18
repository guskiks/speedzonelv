import SwiftUI
import UIKit

struct ZoneEditorContext: Identifiable {
    let id = UUID()
    let zone: SpeedZone?
    let template: ZoneTemplate?
}

struct ZoneEditorView: View {
    @Environment(AppEnvironment.self) private var app
    @EnvironmentObject private var userZones: UserZoneStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ZoneDraft
    @State private var errorMessage: String?

    private let editingZone: SpeedZone?

    init(zone: SpeedZone? = nil, template: ZoneTemplate? = nil) {
        self.editingZone = zone
        _draft = State(initialValue: ZoneDraft(zone: zone, template: template))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        basicsCard
                        coordinatesCard
                        enforcementCard
                        sourceCard

                        if let errorMessage {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(errorMessage)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(Theme.red)
                            .padding(12)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Theme.red.opacity(0.09))
                            }
                        }

                        Button(action: save) {
                            Label(editingZone == nil ? "Pievienot zonu" : "Saglabāt izmaiņas", systemImage: "checkmark")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Text("Manuālās zonas tiek glabātas tikai šajā ierīcē. Pārbaudi ceļa zīmes un ievadi koordinātas tikai tad, ja esi pārliecināts par posma sākumu un finišu.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Theme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(editingZone == nil ? "Jauna zona" : "Rediģēt zonu")
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

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Pamatinformācija")

            LabeledField(label: "Nosaukums", text: $draft.name, placeholder: "Piemēram, A9 Kaģi")
            LabeledField(label: "Ceļa numurs", text: $draft.road, placeholder: "A9")
            LabeledField(label: "Virziens (apraksts)", text: $draft.directionDescription, placeholder: "Rīgas virzienā")
        }
        .dashboardCard()
    }

    private var coordinatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Koordinātas")
                Spacer()
                if let distance = draft.coordinateDistance {
                    Text(Fmt.distance(distance))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            coordinateRow(
                title: "Sākums",
                latitude: $draft.startLatitude,
                longitude: $draft.startLongitude,
                captureTitle: "Izmantot pašreizējo GPS sākumam"
            ) {
                captureCurrentLocation(isStart: true)
            }

            coordinateRow(
                title: "Finišs",
                latitude: $draft.endLatitude,
                longitude: $draft.endLongitude,
                captureTitle: "Izmantot pašreizējo GPS finišam"
            ) {
                captureCurrentLocation(isStart: false)
            }

            HStack(spacing: 8) {
                Button {
                    if let distance = draft.coordinateDistance {
                        draft.lengthMeters = String(format: "%.0f", distance)
                    }
                } label: {
                    Label("Aprēķināt garumu", systemImage: "ruler")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(draft.coordinateDistance == nil)

                Button {
                    swapCoordinates()
                } label: {
                    Label("Mainīt virzienu", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            LabeledField(
                label: "Oficiālais garums (m)",
                text: $draft.lengthMeters,
                placeholder: "Automātiski no koordinātām",
                keyboard: .numberPad
            )
        }
        .dashboardCard()
    }

    private var enforcementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Kontroles parametri")

            VStack(alignment: .leading, spacing: 6) {
                Text("Braukšanas virziens")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)

                Picker("Virziens", selection: $draft.direction) {
                    ForEach(ZoneDirection.allCases, id: \.self) { direction in
                        Text(direction.shortLabel).tag(direction)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Oficiālais ātruma limits")
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(Fmt.speedLimit(draft.speedLimitKmh))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }

                Stepper(
                    "Limits",
                    value: $draft.speedLimitKmh,
                    in: 20...160,
                    step: 5
                )
                .labelsHidden()
            }

            Toggle(isOn: $draft.isVerified) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Esmu pārbaudījis šo zonu")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Piezīme tiks saglabāta kā pārbaudīta ar šodienas datumu.")
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .tint(Theme.mint)
        }
        .dashboardCard()
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Avots un piezīmes")

            LabeledField(label: "Avota nosaukums", text: $draft.sourceName, placeholder: "Manuāli pievienota")
            LabeledField(label: "Avota saite (nav obligāta)", text: $draft.sourceURL, placeholder: "https://…", keyboard: .URL)
            LabeledField(label: "Piezīmes", text: $draft.notes, placeholder: "Papildu informācija")
        }
        .dashboardCard()
    }

    private func coordinateRow(
        title: String,
        latitude: Binding<String>,
        longitude: Binding<String>,
        captureTitle: String,
        capture: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                Button(action: capture) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                        Text("GPS")
                    }
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Theme.ice)
                }
                .accessibilityLabel(captureTitle)
            }

            HStack(spacing: 8) {
                LabeledField(label: "Platums", text: latitude, placeholder: "56.123456", keyboard: .numbersAndPunctuation, compact: true)
                LabeledField(label: "Garums", text: longitude, placeholder: "24.123456", keyboard: .numbersAndPunctuation, compact: true)
            }
        }
    }

    private func captureCurrentLocation(isStart: Bool) {
        guard let coordinate = app.dashboard.location.latestFix?.coordinate else {
            errorMessage = "Vēl nav GPS signāla. Palaid GPS sekošanu un mēģini vēlreiz."
            return
        }

        let latitude = String(format: "%.6f", coordinate.latitude)
        let longitude = String(format: "%.6f", coordinate.longitude)

        if isStart {
            draft.startLatitude = latitude
            draft.startLongitude = longitude
        } else {
            draft.endLatitude = latitude
            draft.endLongitude = longitude
        }

        if let distance = draft.coordinateDistance {
            draft.lengthMeters = String(format: "%.0f", distance)
        }
        errorMessage = nil
    }

    private func swapCoordinates() {
        // `draft` is a computed Binding-backed property, so passing two of
        // its members as inout arguments creates overlapping writeback in
        // recent Swift compilers. Swap local values, then assign once.
        let startLatitude = draft.startLatitude
        let startLongitude = draft.startLongitude
        draft.startLatitude = draft.endLatitude
        draft.startLongitude = draft.endLongitude
        draft.endLatitude = startLatitude
        draft.endLongitude = startLongitude
        draft.direction = draft.direction == .startToEnd ? .endToStart : .startToEnd
    }

    private func save() {
        do {
            let zone = try draft.buildZone(existingID: editingZone?.id)
            if editingZone == nil {
                try userZones.add(zone)
            } else {
                try userZones.update(zone)
            }
            app.refreshZones()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Draft

struct ZoneDraft {
    var name: String
    var road: String
    var directionDescription: String
    var startLatitude: String
    var startLongitude: String
    var endLatitude: String
    var endLongitude: String
    var lengthMeters: String
    var speedLimitKmh: Int
    var direction: ZoneDirection
    var isVerified: Bool
    var sourceName: String
    var sourceURL: String
    var notes: String

    init(zone: SpeedZone? = nil, template: ZoneTemplate? = nil) {
        if let zone {
            name = zone.name
            road = zone.road
            directionDescription = zone.directionDescription ?? ""
            startLatitude = String(format: "%.6f", zone.start.latitude)
            startLongitude = String(format: "%.6f", zone.start.longitude)
            endLatitude = String(format: "%.6f", zone.end.latitude)
            endLongitude = String(format: "%.6f", zone.end.longitude)
            lengthMeters = String(format: "%.0f", zone.officialLengthMeters)
            speedLimitKmh = zone.speedLimitKmh
            direction = zone.direction
            isVerified = zone.verification == .verified
            sourceName = zone.source.name
            sourceURL = zone.source.url ?? ""
            notes = zone.notes ?? ""
            return
        }

        if let template {
            name = template.name
            road = template.road
            directionDescription = ""
            startLatitude = ""
            startLongitude = ""
            endLatitude = ""
            endLongitude = ""
            lengthMeters = String(format: "%.0f", template.lengthMeters)
            speedLimitKmh = template.suggestedSpeedLimitKmh
            direction = .startToEnd
            isVerified = false
            sourceName = template.sourceName
            sourceURL = template.sourceURL ?? ""
            notes = "\(template.rangeText). \(template.note)"
            return
        }

        name = ""
        road = ""
        directionDescription = ""
        startLatitude = ""
        startLongitude = ""
        endLatitude = ""
        endLongitude = ""
        lengthMeters = ""
        speedLimitKmh = 90
        direction = .startToEnd
        isVerified = false
        sourceName = "Manuāli pievienota"
        sourceURL = ""
        notes = "Manuāli pievienota zona. Pārbaudi ceļa zīmes."
    }

    var coordinateDistance: Double? {
        guard let start = startCoordinate, let end = endCoordinate else { return nil }
        let distance = start.distance(to: end)
        return distance.isFinite && distance > 0 ? distance : nil
    }

    var startCoordinate: Coordinate? {
        parseCoordinate(latitude: startLatitude, longitude: startLongitude)
    }

    var endCoordinate: Coordinate? {
        parseCoordinate(latitude: endLatitude, longitude: endLongitude)
    }

    func buildZone(existingID: String?) throws -> SpeedZone {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ZoneDraftError.missing("Ievadi zonas nosaukumu.")
        }
        guard !road.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ZoneDraftError.missing("Ievadi ceļa numuru.")
        }
        guard let start = startCoordinate, let end = endCoordinate else {
            throw ZoneDraftError.invalid("Ievadi derīgas sākuma un finiša koordinātas.")
        }
        guard start != end else {
            throw ZoneDraftError.invalid("Sākums un finišs nevar būt vienā punktā.")
        }

        let trimmedLength = lengthMeters.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedLength = parseNumber(trimmedLength)
        let length = parsedLength ?? start.distance(to: end)

        guard length.isFinite, length >= 40 else {
            throw ZoneDraftError.invalid("Posma garumam jābūt vismaz 40 m.")
        }

        let today = Self.dateString(Date())
        let source = ZoneSource(
            name: sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Manuāli pievienota"
                : sourceName.trimmingCharacters(in: .whitespacesAndNewlines),
            url: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : sourceURL.trimmingCharacters(in: .whitespacesAndNewlines),
            license: nil,
            retrievedAt: today
        )

        return SpeedZone(
            id: existingID ?? "user-\(UUID().uuidString.lowercased())",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            road: road.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            direction: direction,
            directionDescription: directionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : directionDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            start: start,
            end: end,
            officialLengthMeters: length,
            speedLimitKmh: min(max(speedLimitKmh, 20), 160),
            source: source,
            verification: isVerified ? .verified : .unverified,
            lastVerified: isVerified ? today : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            entryAdjustmentMeters: nil,
            exitAdjustmentMeters: nil
        )
    }

    private func parseCoordinate(latitude: String, longitude: String) -> Coordinate? {
        guard let lat = parseNumber(latitude), let lon = parseNumber(longitude) else { return nil }
        let coordinate = Coordinate(latitude: lat, longitude: lon)
        return coordinate.isValid ? coordinate : nil
    }

    private func parseNumber(_ value: String) -> Double? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }

    static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

enum ZoneDraftError: LocalizedError {
    case missing(String)
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .missing(let message): return message
        case .invalid(let message): return message
        }
    }
}

// MARK: - Field

private struct LabeledField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var keyboard: UIKeyboardType = .default
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Theme.textTertiary)

            TextField(placeholder, text: $text)
                .font(.system(size: compact ? 12 : 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .default ? .words : .never)
                .padding(.horizontal, 10)
                .padding(.vertical, compact ? 8 : 10)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.045))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Theme.stroke, lineWidth: 1)
                        }
                }
        }
    }
}
