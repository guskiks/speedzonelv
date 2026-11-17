import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case ride
    case history
    case settings

    var title: String {
        switch self {
        case .ride: return "Brauciens"
        case .history: return "Vēsture"
        case .settings: return "Iestatījumi"
        }
    }

    var icon: String {
        switch self {
        case .ride: return "car.fill"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

struct RootView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.scenePhase) private var scenePhase

    // Observing appearance here invalidates the root when the user changes a
    // theme, so the background and all child views pick up the new palette.
    @EnvironmentObject private var appearance: AppearanceSettings

    @State private var selection: AppTab = .ride

    var body: some View {
        ZStack {
            AppBackground()

            Group {
                switch selection {
                case .ride:
                    DashboardView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
            .transition(.opacity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SpeedTabBar(selection: $selection)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .animation(.easeInOut(duration: 0.18), value: selection)
        .environmentObject(app.settings)
        .environmentObject(app.appearance)
        .environmentObject(app.history)
        .environmentObject(app.userZones)
        .task {
            app.bootstrap()
        }
        .onChange(of: scenePhase) { _, newPhase in
            app.dashboard.handleScenePhase(newPhase)
        }
    }
}
