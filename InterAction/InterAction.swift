import SwiftUI

@main
struct InterAction: App {
    
    init() {
        InterActionSystem.registerSystem()
        InterActionComponent.registerComponent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
