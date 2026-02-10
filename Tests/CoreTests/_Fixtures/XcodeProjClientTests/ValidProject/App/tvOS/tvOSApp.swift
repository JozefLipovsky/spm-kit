import SwiftUI
import {{ rootModule }}

@main
struct tvOSApp: App {
    var body: some Scene {
        WindowGroup {
            {{ rootModule }}View()
        }
    }
}
