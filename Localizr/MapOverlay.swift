import SwiftUI
import simd
import SwiftGraph

// Utility functions
func apply_transform(_ trans: Mat3, _ point: Point2) -> Point2 {
    let trans_point = trans * Point3(point.x, point.y, 1)
    return Point2(trans_point.x, trans_point.y)
}

func to_cg(_ trans: Mat3, _ p: Point2) -> CGPoint {
    let p2 = apply_transform(trans, p)
    return CGPoint(x: p2.x, y: p2.y)
}

// Function to calculate the centroid of a polygon
func calculateCentroid(points: [Point2]) -> Point2 {
    var xSum: Double = 0
    var ySum: Double = 0
    let count = Double(points.count)
    
    for point in points {
        xSum += point.x
        ySum += point.y
    }
    
    return Point2(xSum / count, ySum / count)
}

// MapTheme definition
struct MapTheme {
    var border: Color = Color(red: 0.8, green: 0.8, blue: 0.8)
    var path: Color = .blue
    var indicator: Color = .red
    var building: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
    var rooms: Color = Color(red: 0.9, green: 0.9, blue: 1.0)
    var background: Color = Color(red: 0.9, green: 0.9, blue: 0.9)
    var highlighted: Color = Color(red: 0.7, green: 0.7, blue: 1.0)
    var indicator_radius: CGFloat = 30
    var particle_radius: Double = 5
    var path_thickness: Double = 5
}

func rotation_matrix(angle: Double) -> Mat2 {
    return Mat2(rows: [
        [cos(angle), -sin(angle)],
        [sin(angle), cos(angle)],
    ])
}

func rotate(_ axis: Point2, angle: Double) -> Point2 {
    return rotation_matrix(angle: angle) * axis
}

// Rendering functions
func RenderLocationIndicator(context: GraphicsContext, theme: MapTheme, trans: Mat3, pose: Pose, radius: CGFloat = -1, color: Color = .blue) {
    let radius = radius == -1 ? theme.indicator_radius : radius
    
    let pos = Point2(pose.pos.x, pose.pos.y)
    let dir3 = pose.rot.act(Point3(0,1,0))
    let dir = simd_normalize(Point2(dir3.x,dir3.y))
    
    let dir_offset = radius*dir / trans[0][0]
    
    context.fill(Path { path in
        path.move(to: to_cg(trans, pos + rotate(0.3*dir_offset, angle: -M_PI/2)))
        path.addLine(to: to_cg(trans, pos + rotate(dir_offset, angle: 0)))
        path.addLine(to: to_cg(trans, pos + rotate(0.3*dir_offset, angle: M_PI/2)))
        //path.addArc(center: to_cg(trans, position), radius: radius, startAngle: Angle.radians(0.0), endAngle: Angle.radians(2 * Double.pi), clockwise: true)
    }, with: .color(color))
}

func RenderParticles(context: GraphicsContext, theme: MapTheme, trans: Mat3, particles: [Pose]) {
    for p in particles {
        RenderLocationIndicator(context: context, theme: theme, trans: trans, pose: p, radius: theme.particle_radius)
    }
}

func Polygon(trans: Mat3, points: [Point2], close: Bool = true) -> Path {
    return Path { path in
        path.move(to: to_cg(trans, points[0]))
        for i in 1..<points.count {
            path.addLine(to: to_cg(trans, points[i]))
        }
        if close {
            path.addLine(to: to_cg(trans, points[0]))
        }
    }
}

func RenderPathIndicator(context: GraphicsContext, theme: MapTheme, trans: Mat3, path: NavigationPath, thickness: CGFloat = 2, stroke: Color = .red) {
    let waypoints = path.path.map { node in Point2(node.pos.x, node.pos.y) }
    let stride = 8
    
    context.stroke(Path { path in
        path.move(to: to_cg(trans, waypoints[0]))
        
        var i = stride
        while i < waypoints.count {
            /*let point0 = waypoints[i-stride]
            let point1 = waypoints[i]
            let point2 = waypoints[i+stride]
            
            let control1 = point0
            let point = point1
            let control2 = point1 - (point2-point1)
            */
            path.addLine(to: to_cg(trans,waypoints[i]))
            //.addCurve(to: to_cg(trans, point), control1: to_cg(trans, control1), control2: to_cg(trans, control2))
            i += stride
        }
        if let last = waypoints.last {
            path.addLine(to: to_cg(trans,last))
        }
    }, with: .color(theme.path), lineWidth: theme.path_thickness)
}

func RenderFloor(context: GraphicsContext, theme: MapTheme, trans: Mat3, floor: Floor) {
    let scale = trans[0][0]
    
    let building = Polygon(trans: trans, points: floor.outline)
    context.fill(building, with: .color(theme.building))
    context.stroke(building, with: .color(theme.border), lineWidth: 1.0 * scale)
    
    for area in floor.walkable_areas {
        let points = area.map { coord in
            Point2(coord[0], coord[1])
        }
        let walkable_render = Polygon(trans: trans, points: points)
        context.fill(walkable_render, with: .color(Color(red: 0.9, green: 1.0, blue: 0.9)))
    }
    
    
    for room in floor.locations {
        let min = apply_transform(trans, room.contour.reduce(Point2(1e10, 1e10), simd_min))
        let max = apply_transform(trans, room.contour.reduce(Point2(-1e10, -1e10), simd_max))
        let width = max.x - min.x
        let height = max.y - min.y
        let minSize = 50.0
        let path = Polygon(trans: trans, points: room.contour)
        context.fill(path, with: .color(theme.rooms))
        context.stroke(path, with: .color(theme.border), lineWidth: 0.3 * scale)
        if width > minSize {
            context.draw(Text(room.label).foregroundColor(.black), in: CGRect(x: min.x + width / 3, y: max.y - height / 3, width: width / 2, height: height / 2))
        }
    }
}

func RenderHighlightedRoom(context: GraphicsContext, theme: MapTheme, trans: Mat3, contour: [Point2]) {
    let path = Polygon(trans: trans, points: contour)
    context.fill(path, with: .color(theme.highlighted))
    context.stroke(path, with: .color(theme.border), lineWidth: 0.3 * trans[0][0])
}

struct MapOverlayView: View {
    var theme: MapTheme = MapTheme()
    var floor: Floor?
    var pose: Pose?
    var particles: [Pose]
    var path: NavigationPath?
    var world_to_image: Mat3
    var mode : NavigationModeState
    var localize : () -> Void
    var roomContour: [Point2]
    
    @State var scale: CGFloat = 1.0
    @State var base_scale: CGFloat = 1.0
    @State var offset_base: Point2 = Point2(x: 0, y: 0)
    @State var offset: Point2 = Point2(x: 0, y: 0)
    @State var size: CGSize = CGSize(width: 1, height: 1)
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                if size != self.size {
                    DispatchQueue.main.async { self.size = size }
                }
                let size = Point2(x: size.width, y: size.height)
                let size_a = max(size.x, size.y)
                let scale_to_rect = Mat3([size_a, 0, 0], [0, -size_a, 0], [0, size.y, 1])
                let viewpoint = Mat3([scale * base_scale, 0, (offset.x + offset_base.x)], [0, scale * base_scale, (offset.y + offset_base.y)], [0, 0, 1]).transpose
                let trans = viewpoint * scale_to_rect * world_to_image
                
                if let fl = floor {
                    RenderFloor(context: context, theme: theme, trans: trans, floor: fl)
                    
                }
            
                RenderParticles(context: context, theme: theme, trans: trans, particles: particles)
                
                if let pose = self.pose {
                    let loc = pose.pos
                    RenderLocationIndicator(context: context, theme: theme, trans: trans, pose: pose)
                }
                
                if !roomContour.isEmpty {
                    RenderHighlightedRoom(context: context, theme: theme, trans: trans, contour: roomContour)
                }
                
                if let path = path {
                    RenderPathIndicator(context: context, theme: theme, trans: trans, path: path)
                }
    
            }
            .onChange(of: floor?.locations.count) {
                self.centerMap()
            }
            .background(theme.background)
            .gesture(DragGesture().onChanged { value in offset = Point2(x: value.translation.width, y: value.translation.height) }
                .onEnded { _ in offset_base += offset; offset = Point2(x: 0, y: 0) })
            .gesture(MagnificationGesture().onChanged { newScale in
                let center = Point2(size.width / 2, size.height / 2)
                offset_base = center - newScale / scale * (center - offset_base)
                scale = newScale
            }.onEnded { _ in base_scale *= scale; scale = 1.0 })
            
            // Zoom in/out buttons
            
            VStack {
                HStack {
                    Spacer()
                    VStack {
                        Button(action: {
                            centerMap()
                        }) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                                .padding()
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        
                        Button(action: {
                            scale *= 1.1
                            base_scale *= 1.1
                            
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        
                        
                        Button(action: {
                            scale *= 0.9
                            base_scale *= 0.9
                            
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        
                        Button(action: {
                            self.localize()
                        }) {
                            Image(systemName: "location.circle")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        
                        
                        Spacer()
                    }
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onChange(of: roomContour) { newValue in
            if !newValue.isEmpty {
                centerMapOnRoomCentroid()
            }
        }
    }
    
    func centerMapOnPos(centroid: Point2) {
        let size = Point2(x: self.size.width, y: self.size.height)
        let size_a = max(size.x, size.y)
        let scale_to_rect = Mat3([size_a, 0, 0], [0, -size_a, 0], [0, size.y, 1])
        let viewpoint = Mat3([scale * base_scale, 0, (offset.x + offset_base.x)], [0, scale * base_scale, (offset.y + offset_base.y)], [0, 0, 1]).transpose
        let trans = viewpoint * scale_to_rect * world_to_image
        
        // Transform the centroid to the view coordinates
        let centroidInView = apply_transform(trans, centroid)
        
        // Calculate the new offset to center the centroid in the view
        offset_base = Point2(x: size.x / 2 - centroidInView.x, y: size.y / 2 - centroidInView.y)
        
        print("hello3")
    }
    
    func centerMap() {
        if let pose = self.pose {
            centerMapOnPos(centroid: Point2(pose.pos.x, pose.pos.y))
        } else {
            centerMapOnPos(centroid: Point2())
        }
    }
    
    func centerMapOnRoomCentroid() {
        print("hello1")
        if !roomContour.isEmpty {
            print("hello2")
            let centroid = calculateCentroid(points: roomContour)
            centerMapOnPos(centroid: centroid)
        }
    }
}

struct MapOverlay: View {
    @EnvironmentObject var buildingService: BuildingService
    @EnvironmentObject var locationService: LocalizerSession
    @EnvironmentObject var navigationService: NavigationSession
    var mode : NavigationModeState
    @State private var isLoading: Bool = false
    @State private var floor: Floor?
    @State private var world_to_image: Mat3 = Mat3(diagonal: Point3(1, 1, 1))
    //@State private var roomContour: [Point2] = []
    
    func loadMap() {
        
        isLoading = true
  
        buildingService.loadFloormap(floor: "G", on_success: { floor in
            let max = floor.outline.reduce(Point2(-Double.infinity, -Double.infinity), simd_max)
            let min = floor.outline.reduce(Point2(Double.infinity, Double.infinity), simd_min)
            let image_to_world: Mat3 = Mat3(
                [(max.x - min.x), 0, -min.x],
                [0, (max.y - min.y), -min.y],
                [0, 0, 1]
            ).transpose
        
            print("Map loaded successfully")
            
            let world_to_image = simd_inverse(image_to_world)
            
            DispatchQueue.main.async {
                self.floor = floor
                self.world_to_image = world_to_image
                self.isLoading = false
            }
        }, on_failure: { error in
            self.isLoading = false
            print("Failed to load floor map: \(error)")  // Debug statement
        })
    }
    
    var roomContour : [Point2] {
        var roomContour : [Point2] = []
        if case let .destinationRoom(label, center) = navigationService.mode {
            if let floor = self.floor {
                roomContour = floor.locations.filter({ room in (room.label == label) }).flatMap({ room in room.contour })
            }
        }
        return roomContour
    }
    
    var body: some View {
        /*NavigationView {*/
        MapOverlayView(theme: MapTheme(), floor: floor, pose: locationService.pose, particles: locationService.public_particles, path : navigationService.nodePath, world_to_image: world_to_image, mode: mode, localize: { locationService.localize() }, roomContour: roomContour)
            .onAppear(perform: loadMap)
        /*.navigationViewStyle(StackNavigationViewStyle())
        .navigationBarTitleDisplayMode(.inline)*/
    }
}

