import SwiftUI
import {{ rootModule }}

@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            {{ rootModule }}View()
        }
    }
}
