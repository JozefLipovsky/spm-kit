import SwiftUI
import {{ rootModule }}

@main
struct watchOSApp: App {
    var body: some Scene {
        WindowGroup {
            {{ rootModule }}View()
        }
    }
}
