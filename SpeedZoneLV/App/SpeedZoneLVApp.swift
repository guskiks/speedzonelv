import SwiftUI

@main
struct SpeedZoneLVApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environmentObject(environment.settings)
                .environmentObject(environment.appearance)
                .environmentObject(environment.history)
                .environmentObject(environment.userZones)
                .preferredColorScheme(.dark)
        }
    }
}
