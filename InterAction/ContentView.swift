import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        ARContainer().ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ARContainer().ignoresSafeArea()
    }
}

struct ARContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> PlayView {
        let arView = PlayView(frame: .zero)
        arView.setup()
        return arView
    }
    
    func updateUIView(_ uiView: PlayView, context: Context) { }
}
