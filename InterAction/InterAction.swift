import SwiftUI

@main
struct InterAction: App {
    
    init() {
        InterActionSystem.registerSystem()
        InterActionComponent.registerComponent()
        CameraComponent.registerComponent()
        GrabbedComponent.registerComponent()
        CrosshairComponent.registerComponent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
