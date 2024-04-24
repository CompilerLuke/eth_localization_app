import SwiftUI
import RealityKit

struct LocalizeResponse : Decodable {
    var pos: Point3
    var node: Int
}

class AppTheme : ObservableObject {
    var icons : Color = .black
    var fg : Color = .black
    var card1_bg : Color = Color(red: 0.95, green: 0.95, blue: 0.95)
    var card2_bg : Color = Color(red: 0.9, green: 0.9, blue: 0.9)
    var card2_shadow : some View {
        card2_bg //.shadow(color: Color(red: 0.9, green: 0.9, blue: 0.9), radius: 5)
    }
    var card3_bg : Color = Color(red: 0.85, green: 0.85, blue: 0.85)
    var card3_shadow : some View {
        card3_bg //.shadow(color: Color(red: 0.85, green: 0.85, blue: 0.85), radius: 5)
    }
}

enum AppRoute {
    
}

struct MapARToggle : View {
    @EnvironmentObject var theme : AppTheme
    @EnvironmentObject var localizerSession : LocalizerSession
    @State var mapOverlay : Bool = true
    
    func localize() {
        localizerSession.localize()
    }
    
    var body : some View {
        VStack {
            HStack(alignment: .bottom)  {
                Button(action: localize) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 30))
                        .foregroundColor(theme.card2_bg)
                        .cornerRadius(15)
                }
                .padding(10)
                Spacer()
                HStack {
                    Button(action: { mapOverlay = true }) {
                        Text("MAP")
                    }
                    .padding(10)
                    .background(mapOverlay ? theme.card1_bg : theme.card2_bg)
                    Button(action: { mapOverlay = false }) {
                        Text("CAMERA")
                    }
                    .padding(10)
                    .background(mapOverlay ? theme.card2_bg : theme.card1_bg)
                        
                }
                .padding(10)
                .background(theme.card2_bg.cornerRadius(15))
                Spacer()
            }
            .padding(10)
            .frame(alignment: .topLeading)
            
            ZStack(alignment: .topTrailing) {
                if(mapOverlay) {
                    MapOverlay()
                    /*LocalizeOverlay()
                        .frame(width: UIScreen.main.bounds.width*0.5, height: UIScreen.main.bounds.width*0.5)
                        .padding(10)*/
                } else {
                    LocalizeOverlay()
                    MapOverlay()
                        .frame(width: UIScreen.main.bounds.width*0.5, height: UIScreen.main.bounds.width*0.5)
                        .padding(10)
                }
            }
        }
    }
}

struct MainContentView : View {
    @EnvironmentObject var theme : AppTheme
    @EnvironmentObject var localizerSession : LocalizerSession
    
    var body: some View {
        ZStack(alignment: .top) {
            MapARToggle()
            
            VStack{
                Spacer()
                SwipeupCard(content: {
                    NavigationSearch()
                }).background(theme.card1_bg)
            }
        }
        .frame(maxHeight: .infinity)
        .background(theme.card1_bg)
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
