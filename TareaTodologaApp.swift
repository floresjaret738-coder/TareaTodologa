import SwiftUI

@main
@MainActor
struct TareaTodologaApp: App {
    @StateObject private var app = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(app)
                .preferredColorScheme(app.settings.colorScheme)
        }
    }
}
