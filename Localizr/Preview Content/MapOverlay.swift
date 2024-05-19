import SwiftUI
import simd

typealias Mat3 = simd_double3x3
typealias Point2 = simd_double2
typealias Point3 = simd_double3



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

// Rendering functions
func RenderLocationIndicator(context: GraphicsContext, theme: MapTheme, trans: Mat3, position: Point2, radius: CGFloat = 5, color: Color = .red) {
    context.fill(Path { path in
        path.addArc(center: to_cg(trans, position), radius: radius, startAngle: Angle.radians(0.0), endAngle: Angle.radians(2 * Double.pi), clockwise: true)
    }, with: .color(theme.indicator))
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

func RenderPathIndicator(context: GraphicsContext, theme: MapTheme, trans: Mat3, waypoints: [Point2], thickness: CGFloat = 2, stroke: Color = .red) {
    context.stroke(Polygon(trans: trans, points: waypoints, close: false), with: .color(theme.path), lineWidth: 5)
}

func RenderFloor(context: GraphicsContext, theme: MapTheme, trans: Mat3, floor: Floor) {
    let scale = trans[0][0]
    let building = Polygon(trans: trans, points: floor.outline)
    context.fill(building, with: .color(theme.building))
    context.stroke(building, with: .color(theme.border), lineWidth: 1.0 * scale)
    
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

// MapTheme definition
struct MapTheme {
    var border: Color = Color(red: 0.8, green: 0.8, blue: 0.8)
    var path: Color = .blue
    var indicator: Color = .red
    var building: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
    var rooms: Color = Color(red: 0.9, green: 0.9, blue: 1.0)
    var background: Color = Color(red: 0.9, green: 0.9, blue: 0.9)
}

struct MapOverlayView: View {
    var theme: MapTheme = MapTheme()
    var floor: Floor?
    var location: Point3?
    var path: [Point2]
    var world_to_image: Mat3
    var roomContourSet: Bool = false
    var roomContour: [Point2]  {
        didSet {
            if !roomContour.isEmpty {
                roomContourSet = true
                print ("room contour set")
            }
        }
    }
    
    
    @State var scale: CGFloat = 1.0
    @State var base_scale: CGFloat = 1.0
    @State var offset_base: Point2 = Point2(x: 0, y: 0)
    @State var offset: Point2 = Point2(x: 0, y: 0)
    @State var size: CGSize = CGSize(width: 1, height: 1)
    
   
    
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                print("Canvas size: \(size)") // Debug statement
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
                
                if !roomContour.isEmpty {
                    let centroid = calculateCentroid(points: roomContour)
                    RenderLocationIndicator(context: context, theme: theme, trans: trans, position: centroid, radius: 10, color: .red)
                }
                if path.count > 0 {
                    RenderPathIndicator(context: context, theme: theme, trans: trans, waypoints: path)
                }
                if let loc = location {
                    RenderLocationIndicator(context: context, theme: theme, trans: trans, position: Point2(loc.x, loc.y))
                }
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
                            centerMapOnCentroid()
                            
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
                        
                        
                        Spacer()
                    }
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            .onChange(of: roomContourSet) { newValue in
                        if newValue {
                            // Perform action when roomContourSet is true
                            centerMapOnCentroid()
                        }
            }
        }
        
    }
    
    func centerMapOnCentroid() {
            print("hello1")
            if !roomContour.isEmpty {
                print("hello2")
                let centroid = calculateCentroid(points: roomContour)
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
        }
}

struct MapOverlay: View {
    var room: String
    @EnvironmentObject var buildingService: BuildingService
    @State private var isLoading: Bool = false
    @State private var floor: Floor?
    @State private var world_to_image: Mat3 = Mat3(diagonal: Point3(1, 1, 1))
    @State private var roomContour: [Point2] = []
    
    
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
            
            let world_to_image = simd_inverse(image_to_world)
            let roomContour = floor.locations.first(where: { $0.label == room })?.contour ?? []

            
            
            
            DispatchQueue.main.async {
                self.floor = floor
                self.world_to_image = world_to_image
                self.isLoading = false
                self.roomContour = roomContour
                print("Map loaded successfully")  // Debug statement
            
            }
        }, on_failure: { error in
            self.isLoading = false
            print("Failed to load floor map: \(error)")  // Debug statement
        })
    }
    
    var body: some View {
            let path: [Point2] = [] // Provide the path data if necessary
            NavigationView {
                MapOverlayView(theme: MapTheme(), floor: floor, location: nil, path: path, world_to_image: world_to_image, roomContour: roomContour)
                    .navigationBarTitle("Destination : \(room)", displayMode: .inline)
                    
                    .onAppear {
                        loadMap()
                       
                    }
            }
            .navigationViewStyle(StackNavigationViewStyle()) // Ensure the style is appropriate for your app
            .navigationBarTitleDisplayMode(.inline) // Ensure the title is displayed inline
            
        }
}
