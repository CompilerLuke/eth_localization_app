import SwiftUI
import Combine
import RealityKit
import ARKit

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
    @EnvironmentObject var navigationSession : NavigationSession
    
    @State var session_coordinator : CoordinatorARSession? = nil
    @State var anchor : AnchorEntity? = nil
    @State var arrow : ModelEntity? = nil
    @State var arrows_placed : [ModelEntity] = []
    
    let path_spacing : Int = 10
    let arrow_scale : Float = 0.002
    let arrow_count = 10
    
    func updateArrows(nodePath: NavigationPath?) {
        guard let anchor : AnchorEntity = self.anchor else { return }
        guard let nodePath = nodePath else { return }
        guard let model = self.arrow else { return }
        
        let world2arkit = Pose(from: anchor.transform).inverse * localizerSession.world_to_arkit()
        
        var path : [Point3] = []
        var i = 0
        while i < min(nodePath.path.count, arrow_count*path_spacing) {
            path.append(nodePath.path[i].pos)
            i += path_spacing
        }
        
        for i in 1..<path.count {
            var entity : ModelEntity
            if i < self.arrows_placed.count {
                entity = self.arrows_placed[i-1]
            } else {
                entity = model.clone(recursive: true)
                anchor.addChild(entity)
                self.arrows_placed.append(entity)
            }
            
            let pos0 = path[i-1]
            let pos1 = path[i]
            
            let dir = pos1 - pos0
            var angle = atan2(dir.y, dir.x)-Double.pi/2 // (0,1) corresponds to 0, instead of the trigonometric (1,0)
            angle += Double.pi // orient arrow
            
            let rot = Quat(angle: angle, axis: Point3(0,0,1)) * Quat(angle: Double.pi/2, axis: Point3(1,0,0))
            var trans = world2arkit * Pose(rot: rot, pos: pos1)
            trans.pos.z = 0
            
            var ar_trans = trans.transform
            ar_trans.scale = simd_float3(arrow_scale,arrow_scale,arrow_scale)

            entity.isEnabled = true
            entity.transform = trans.transform
        }
        
        for i in path.count-1..<self.arrows_placed.count {
            self.arrows_placed[i].isEnabled = false
        }
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        
        localizerSession.setArView(arView: arView)
        
        guard let arrow_url = Bundle.main.url(forResource: "arrow", withExtension: "usdc", subdirectory: "Assets3D")
        else {
            print("Could not find arrow asset")
            return arView
        }
        
        guard let arrow = try? Entity.loadModel(contentsOf: arrow_url)
        else {
            print("Could not load arrow entity")
            return arView
        }
        
        let material = SimpleMaterial(color: UIColor(red:0.6,green:0.6,blue:1.0,alpha:0.8), roughness: 1.00, isMetallic: false)
        arrow.model?.materials = [material]
        
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(1.0, 1.0)))
        arView.scene.addAnchor(anchor)
    
        DispatchQueue.main.async {
            self.arrow = arrow
            self.session_coordinator = CoordinatorARSession(session: localizerSession, arView: arView)
            self.anchor = anchor
            print("Set anchor to ", self.anchor, anchor)
        }
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class CoordinatorARSession : NSObject, ARSessionDelegate {
        var session: LocalizerSession
        var arView: ARView
        
        init(session: LocalizerSession, arView: ARView) {
            self.session = session
            self.arView = arView
            
            super.init()
            arView.session.delegate = self
                
            // Set up AR session configuration
            //let configuration = ARWorldTrackingConfiguration()
            //arView.session.run(configuration)
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Get the camera intrinsics from the current frame
            let camera = frame.camera
            let intrinsics = camera.intrinsics
            
            // The intrinsics matrix is a 3x3 matrix of type simd_float3x3
            //print("Camera Intrinsics: \(intrinsics)")
            
            // Extract focal length and principal point
            let focalLengthX = intrinsics.columns.0.x
            let focalLengthY = intrinsics.columns.1.y
            let principalPointX = intrinsics.columns.2.x
            let principalPointY = intrinsics.columns.2.y
            
            self.session.intrinsics = [focalLengthY, focalLengthX, principalPointY, principalPointX]
            
            
            
            //print("Focal Length X: \(focalLengthX), Focal Length Y: \(focalLengthY)")
            //print("Principal Point X: \(principalPointX), Principal Point Y: \(principalPointY)")
        }
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        private var cancellable: AnyCancellable?
        
        init(_ parent: LocalizeOverlay) {
            super.init()
            self.cancellable = parent.navigationSession.$nodePath.sink { path in
                DispatchQueue.main.async {
                    parent.updateArrows(nodePath: path)
                }
            }
        }
        
        deinit {
            cancellable?.cancel()
        }
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    Text("")
    //ContentView(localizerSession: nil)
}
