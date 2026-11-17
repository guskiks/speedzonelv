import CoreLocation
import SwiftUI

struct IdleDashboardView: View {
    @EnvironmentObject private var appearance: AppearanceSettings

    let verifiedZoneCount: Int
    let manualZoneCount: Int
    let isTracking: Bool
    let status: String
    let currentSpeedKmh: Double
    let accuracyMeters: Double?
    let authorizationStatus: CLAuthorizationStatus
    let onRequestPermission: () -> Void
    let onStartTracking: () -> Void
    let onStopTracking: () -> Void

    private var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    private var permissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    private var statusColor: Color {
        if isTracking { return Theme.mint }
        return Theme.ice
    }

    var body: some View {
        VStack(spacing: 14) {
            statusCard

            if appearance.showsSpeedGauge {
                SpeedGaugeView(
                    speedKmh: currentSpeedKmh,
                    limitKmh: nil,
                    targetKmh: nil,
                    accuracyMeters: accuracyMeters,
                    isIdle: !isTracking
                )
            }

            if !hasLocationPermission {
                permissionCard
            }

            controlsCard

            if appearance.showsOnboarding {
                OnboardingStepsCard()
            }

            HStack(spacing: 12) {
                Label("\(verifiedZoneCount) datubāzē", systemImage: "checkmark.shield.fill")
                Label("\(manualZoneCount) manuālas", systemImage: "square.and.pencil")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.textTertiary)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusPill(text: status, color: statusColor)
                Spacer()
                Image(systemName: isTracking ? "location.fill" : "location.slash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Vidējā ātruma kontrole")

                Text(isTracking ? "GPS aktīvs" : "Nav aktīvas zonas")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text(statusDescription)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .dashboardCard()
    }

    private var statusDescription: String {
        if isTracking {
            return "Tuvojoties pārbaudītai vai manuāli pievienotai zonai, mērījums sāksies automātiski. Fonā darbojas tikai ar “Vienmēr” atļauju."
        }
        return "Palaid GPS sekošanu, lai automātiski noteiktu tuvumā esošās zonas."
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: permissionDenied ? "location.slash.fill" : "location.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(permissionDenied ? Theme.red : Theme.amber)

                Text(permissionDenied ? "Atrašanās vieta liegta" : "Nepieciešama GPS atļauja")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            Text(permissionDenied
                 ? "Atver iPhone Iestatījumi → SpeedZone LV → Atrašanās vieta un izvēlies “Vienmēr”, ja gribi fona mērījumu."
                 : "Lai noteiktu iebraukšanu zonā un mērītu vidējo ātrumu, atļauj atrašanās vietu. Fona mērījumam nepieciešama “Vienmēr” atļauja.")
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !permissionDenied {
                Button(action: onRequestPermission) {
                    Label("Atļaut atrašanās vietu", systemImage: "location.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .dashboardCard()
    }

    private var controlsCard: some View {
        VStack(spacing: 10) {
            if isTracking {
                Button(action: onStopTracking) {
                    Label("Apturēt GPS sekošanu", systemImage: "stop.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                Button(action: onStartTracking) {
                    Label("Sākt GPS sekošanu", systemImage: "location.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

            }
        }
    }
}

private struct OnboardingStepsCard: View {
    private struct Step: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
        let tint: Color
    }

    private let steps: [Step] = [
        Step(
            icon: "location.north.fill",
            title: "Automātiska noteikšana",
            detail: "Iebraucot zonā pareizajā virzienā, mērījums sākas pats.",
            tint: Theme.ice
        ),
        Step(
            icon: "chart.xyaxis.line",
            title: "Pilna ātruma līkne",
            detail: "Visa posma ātrums, oficiālais limits un tavs personīgais mērķis vienā grafikā.",
            tint: Theme.mint
        ),
        Step(
            icon: "flag.checkered",
            title: "Finišs un kopsavilkums",
            detail: "Izbraucot no zonas, mērījums beidzas un tiek saglabāts vēsturē.",
            tint: Theme.violet
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Kā tas strādā")

            ForEach(steps) { step in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: step.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(step.tint)
                        .frame(width: 28, height: 28)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(step.tint.opacity(0.11))
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)

                        Text(step.detail)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .dashboardCard()
    }
}
