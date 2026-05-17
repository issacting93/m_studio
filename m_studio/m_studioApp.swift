import SwiftUI

@main
struct m_studioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 1440, height: 850)
        #endif
    }
}
