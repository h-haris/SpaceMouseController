import SwiftUI

@main
struct SpaceMouseControllerApp: App {
    init() {
        // Redirect NSLog (stderr) to a file; readable with: tail -f /tmp/SpaceMouseController.log
        freopen("/tmp/SpaceMouseController.log", "a", stderr)
    }

    var body: some Scene {
        WindowGroup("SpaceMouse Controller") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
