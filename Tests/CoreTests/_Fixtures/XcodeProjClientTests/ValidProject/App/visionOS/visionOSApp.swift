import SwiftUI
import {{ rootModule }}

@main
struct visionOSApp: App {
    var body: some Scene {
        WindowGroup {
            {{ rootModule }}View()
        }
    }
}
