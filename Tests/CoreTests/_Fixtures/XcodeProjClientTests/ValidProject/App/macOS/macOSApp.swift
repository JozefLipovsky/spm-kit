import SwiftUI
import {{ rootModule }}

@main
struct macOSApp: App {
    var body: some Scene {
        WindowGroup {
            {{ rootModule }}View()
        }
    }
}
