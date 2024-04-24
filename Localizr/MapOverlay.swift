import SwiftUI
import simd

typealias Mat3 = simd_double3x3
typealias Point2 = simd_double2
typealias Point3 = simd_double3

func apply_transform(_ trans: Mat3, _ point: Point2) -> Point2 {
    let trans_point = trans * Point3(point.x, point.y, 1)
    return Point2(trans_point.x, trans_point.y)
}

func to_cg(_ trans: Mat3, _ p: Point2) -> CGPoint {
    let p2 = apply_transform(trans, p)
    return CGPoint(x: p2.x, y: p2.y)
}


struct MapTheme {
    var border : Color = Color(red: 0.8, green: 0.8, blue: 0.8)
    var path: Color = .blue
    var indicator: Color = .blue
    var building: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
    var rooms : Color = Color(red: 0.9, green: 0.9, blue: 1.0)
    var background : Color = Color(red: 0.9, green: 0.9, blue: 0.9)
}

func RenderLocationIndicator(
    context: GraphicsContext,
    theme: MapTheme,
    trans: Mat3,
    position: Point2,
    radius: CGFloat = 5,
    color: Color = .blue) {
    
    context.fill(Path { path in
        path.addArc(center: to_cg(trans,position), radius: radius, startAngle: Angle.radians(0.0), endAngle: Angle.radians(2*Double.pi), clockwise: true)
    }, with: .color(theme.indicator))
}

func Polygon(trans: Mat3,points: [Point2],close: Bool = true) -> Path {
    return Path{ path in
        path.move(to: to_cg(trans, points[0]))
        for i in 1...points.count-1 {
            path.addLine(to: to_cg(trans,points[i]))
        }
        if(close) {
            path.addLine(to: to_cg(trans,points[0]))
        }
    }
}

func RenderPathIndicator(
    context: GraphicsContext,
    theme: MapTheme,
    trans: Mat3,
    waypoints: [Point2],
    thickness: CGFloat = 2,
    stroke: Color = Color.blue
) {
    context.stroke(Polygon(trans: trans, points: waypoints, close: false), with: .color(theme.path),  lineWidth:5)
}

func get_label(room: (String, [Point2])) -> String {
    return room.0
}

func RenderFloor(context: GraphicsContext, 
                 theme: MapTheme,
                 trans: Mat3,
                 floor: Floor) {
    let scale = trans[0][0]
    
    let building = Polygon(trans: trans, points: floor.outline)
    context.fill(building, with: .color(theme.building))
    context.stroke(building, with: .color(theme.border), lineWidth: 1.0*scale)
    
    for room in floor.locations {
        let min = apply_transform(trans, room.contour.reduce(Point2(1e10,1e10), simd_min))
        let max = apply_transform(trans, room.contour.reduce(Point2(-1e10,-1e10), simd_max))
        let width = max.x-min.x
        let height = max.y-min.y
        
        let minSize = 50.0

        let path = Polygon(trans: trans, points: room.contour)
        context.fill(path, with: .color(theme.rooms))
        context.stroke(path, with: .color(theme.border), lineWidth: 0.3*scale)
        
        if(width > minSize) {
            context.draw(Text(room.label).foregroundColor(.black),in: CGRect(x: min.x+width/3, y: max.y-height/3, width: width/2, height: height/2))
        }
    }
}

struct MapOverlayView: View {
    var theme: MapTheme = MapTheme() // todo: inject
    var floor: Floor?
    var location : Point3?
    var path: [Point2]
    var world_to_image: Mat3
    @State var scale: CGFloat = 1.0
    @State var base_scale: CGFloat = 1.0
    @State var offset_base: Point2 = Point2(x:0,y:0)
    @State var offset: Point2 = Point2(x:0,y:0)
    @State var size: CGSize = CGSize(width: 1, height: 1)
    
    var body: some View {
        Canvas { context, size in
            if(size != self.size) {
                DispatchQueue.main.async { self.size = size }
            }
            
            let size = Point2(x:size.width,y:size.height)
            
            let size_a = max(size.x, size.y)
            let scale_to_rect = Mat3(
                [size_a,0,0],
                [0,-size_a,0],
                [0,size.y,1]
            )
            let viewpoint =
                Mat3(
                    [scale*base_scale,0,(offset.x+offset_base.x)],
                    [0,scale*base_scale,(offset.y+offset_base.y)],
                    [0,0,1]
                ).transpose
            
            let trans = viewpoint * scale_to_rect * world_to_image

            if let fl = floor {
                RenderFloor(context: context, theme: theme, trans: trans, floor: fl)
            }
            
            if(path.count > 0) {
                RenderPathIndicator(context: context, theme: theme, trans: trans, waypoints: path)
            }
            
            if let loc = location {
                RenderLocationIndicator(context: context, theme: theme, trans: trans, position: Point2(loc.x,loc.y))
            }
        }
        .background(theme.background)
        .gesture(
            DragGesture()
            .onChanged { value in
                offset = Point2(x:value.translation.width,y:value.translation.height)
            }
            .onEnded { _ in
                // Reset offset or perform any other action when the drag ends
                offset_base += offset
                offset = Point2(x:0,y:0)
            }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { newScale in
                    let center = Point2(size.width/2, size.height/2)
                    offset_base = center - newScale/scale * (center - offset_base)
                    scale = newScale
                }
                .onEnded { _ in
                    base_scale *= scale
                    scale = 1.0
                }
        )
        .gesture(
            RotationGesture()
                .onChanged { value in
                    
                }
        )
        //.frame(width: 400, height: 500)
    }
}


struct MapOverlay : View {
    @EnvironmentObject var locationService : LocalizerSession
    @EnvironmentObject var navigationService : NavigationSession
    @EnvironmentObject var buildingService : BuildingService
    @State private var isLoading : Bool = false
    @State private var floor : Floor?
    @State private var world_to_image: Mat3 = Mat3(diagonal: Point3(1,1,1))
    
    func loadMap() {
        isLoading = true
        buildingService.loadFloormap(floor: "", on_success: { floor in
            let max = floor.max
            let min = floor.min
                
            let image_to_world : Mat3 = Mat3(
                [(max.x-min.x), 0, min.x],
                [0, max.y-min.y, min.y],
                [0, 0, 1]
            ).transpose
            
            let world_to_image = simd_inverse(image_to_world)
            
            DispatchQueue.main.async {
                self.floor = floor
                self.world_to_image = world_to_image
                isLoading = false
            }
        }, on_failure: { err in
            isLoading = false
        })
    }
    
    var body: some View {
        let path = navigationService.nodePath.map({ node in Point2(x: node.pos.x, y: node.pos.y)})
        
        MapOverlayView(floor: floor, location: locationService.position, path: path, world_to_image: world_to_image).onAppear(perform: loadMap)
    }
}

#Preview {
    MapOverlayView(
        floor: Floor(min: Point2(x:0.0,y:0.0),
                     max: Point2(x:1.0,y:1.0),outline: [
            Point2(0.1,0.1),Point2(0.1,0.9),Point2(0.9,0.9),Point2(0.9,0)
        ], locations: [Room(
                            id: 0,
                            label: "E3",
                            desc:"Room",
                            contour:[
                            Point2(x:0.3,y:0.3),
                            Point2(x:0.3,y:0.6),
                            Point2(x:0.6,y:0.6),
                            Point2(x:0.6,y:0.3)],
                            type: 0
                   )]),
        location: Point3(0.7,0.5,0), path: [
            Point2(0.3, 0.3),
            Point2(0.3, 0.5),
            Point2(0.7, 0.5)
        ], world_to_image: Mat3(
            [1.0,0,0],
            [0,1.0,0],
            [0,0,1]))
}
