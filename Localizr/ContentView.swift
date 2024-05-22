import SwiftUI
import RealityKit

struct LocalizeResponse : Decodable {
    var pos: Point3
    var node: Int
}

class AppTheme : ObservableObject {
    var icons : Color = .black
    var fg : Color = .black
    var card1_bg: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
    var card2_bg: Color = Color(red: 0.9, green: 0.9, blue: 0.9)
    var card2_shadow: some View {
        card2_bg //.shadow(color: Color(red: 0.9, green: 0.9, blue: 0.9), radius: 5)
    }
    var card3_bg: Color = Color(red: 0.85, green: 0.85, blue: 0.85)
    var card3_shadow: some View {
        card3_bg //.shadow(color: Color(red: 0.85, green: 0.85, blue: 0.85), radius: 5)
    }
    var navigationBarBackground: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
    var navigationBarForeground: Color = .black
    var navigationBarButtonColor: Color = .blue
    
    func applyNavigationBarTheme() {
           let appearance = UINavigationBar.appearance()
           appearance.backgroundColor = UIColor(navigationBarBackground)
           appearance.titleTextAttributes = [.foregroundColor: UIColor(navigationBarForeground)]
           appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(navigationBarForeground)]
           appearance.isTranslucent = false
           appearance.shadowImage = UIImage()
           appearance.setBackgroundImage(UIImage(), for: .default)
       }

    
}


enum AppRoute {
    case home
    case roomSearch
    case localizationPage

}


struct MainContentView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var localizerSession: LocalizerSession
    @State private var currentPage: AppRoute = .home
    
    var body: some View {
        NavigationView {
            VStack {
                if currentPage == .home {
                    HomePage()
                }
            
            }
            .navigationBarHidden(true) // Hide the navigation bar
        }
    }
}







struct LocalizeOverlay: UIViewRepresentable {
    @EnvironmentObject var localizerSession : LocalizerSession
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        localizerSession.arView = arView

        // Create a cube model
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.05

        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model)

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#Preview {
    Text("")
    //ContentView(localizerSession: nil)
}
