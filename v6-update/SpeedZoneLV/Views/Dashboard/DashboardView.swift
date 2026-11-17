import CoreLocation
import SwiftUI

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var app
    @EnvironmentObject private var appearance: AppearanceSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                DashboardHeader(
                    status: app.dashboard.statusMessage,
                    isDemo: app.dashboard.isDemoRunning,
                    isTracking: app.dashboard.isLiveTracking,
                    accuracy: app.dashboard.location.latestFix?.horizontalAccuracy
                )

                if let error = app.dashboard.lastError {
                    ErrorBanner(message: error)
                }

                if let snapshot = app.dashboard.snapshot {
                    switch snapshot.phase {
                    case .completed:
                        CompletedMeasurementView(
                            snapshot: snapshot,
                            onRestart: {
                                if snapshot.isDemo {
                                    app.dashboard.startDemo()
                                } else {
                                    app.dashboard.clearCompletedMeasurement()
                                    app.dashboard.startLiveTracking()
                                }
                            },
                            onClose: { app.dashboard.clearCompletedMeasurement() }
                        )
                    case .approaching, .active:
                        LiveRideView(
                            snapshot: snapshot,
                            onStop: {
                                if snapshot.isDemo {
                                    app.dashboard.stopDemo()
                                } else {
                                    app.dashboard.stopLiveTracking()
                                }
                            },
                            stopLabel: snapshot.isDemo ? "Apturēt demo" : "Apturēt GPS mērījumu"
                        )
                    }
                } else {
                    IdleDashboardView(
                        verifiedZoneCount: app.verifiedZoneCount,
                        manualZoneCount: app.manualZoneCount,
                        isTracking: app.dashboard.isLiveTracking,
                        status: app.dashboard.statusMessage,
                        currentSpeedKmh: app.dashboard.currentSpeedKmh,
                        accuracyMeters: app.dashboard.location.latestFix?.horizontalAccuracy,
                        authorizationStatus: app.dashboard.location.authorizationStatus,
                        onRequestPermission: { app.dashboard.requestLocationPermission() },
                        onStartTracking: { app.dashboard.startLiveTracking() },
                        onStopTracking: { app.dashboard.stopLiveTracking() }
                    )
                }

                if appearance.showsDisclaimer {
                    DisclaimerFooter()
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 10)
            .padding(.bottom, 26)
            .animation(.easeInOut(duration: 0.25), value: app.dashboard.snapshot?.phase)
        }
        .scrollIndicators(.hidden)
    }
}

private struct DashboardHeader: View {
    let status: String
    let isDemo: Bool
    let isTracking: Bool
    let accuracy: Double?

    private var statusColor: Color {
        if isDemo { return Theme.amber }
        if isTracking { return Theme.mint }
        return Theme.textTertiary
    }

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.mint, Theme.mintDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: Theme.mint.opacity(0.25), radius: 14, x: 0, y: 6)

                Image(systemName: "speedometer")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: 0x03130D))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("SPEEDZONE")
                        .font(.system(size: 15, weight: .heavy))
                        .tracking(2.3)
                        .foregroundStyle(Theme.textPrimary)

                    Text("LV")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(Theme.mint)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().fill(Theme.mint.opacity(0.12))
                        }
                }

                Text("Vidējā ātruma asistents")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                StatusPill(text: status, color: statusColor)

                if let accuracy {
                    Text("GPS ±\(Int(accuracy.rounded())) m")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(.top, 2)
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 11.5, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.red)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.red.opacity(0.09))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.red.opacity(0.22), lineWidth: 1)
                }
        }
    }
}
