//
//  LocalizerSession.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//


import Foundation
import ARKit
import RealityKit
import CoreMotion
import Accelerate

struct LocalizerResponse : Decodable {
    struct Pose : Decodable {
        let score : Double
        let rot : Point4
        let pos : Point3
    }
    
    var best_poses : [Pose]
}


class LocalizationService {
    func localize(image: UIImage, intrinsics: [Float], onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        assert(false);
    }
}

class LocalizationServiceDevice : LocalizationService {
    let module : LocalizationModule?
    let max_size : Int = 600
    
    override init() {
        guard let path = Bundle.main.path(forResource: "model.pt", ofType: nil)
        else {
            self.module = nil
            print("Failed to read model.pt path")
            return
        }
        
        self.module = LocalizationModule(fileAtPath: path)
    }
    
    
    override func localize(image: UIImage, intrinsics: [Float], onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        guard let module = self.module
        else {
            onFailure("Could not initialize localization torch module")
            return
        }
        
        
        guard let (buffer, width, height, scale) = image.asFloatArray(max_size: max_size)
        else {
            onFailure("Could not get image array")
            return
        }
        
        assert(intrinsics.count == 4)
        
        func localizeWithRawImage(buffer: UnsafeBufferPointer<Float>, buffer_intrinsics: UnsafeBufferPointer<Float>) {
            guard let baseAddress = buffer.baseAddress
            else {
                onFailure("Image data is null")
                return
            }
            
            guard let intrinsics_baseAddress = buffer_intrinsics.baseAddress
            else {
                onFailure("Intrinsics are missing")
                return
            }
            
            print("\(width)x\(height) Image ", intrinsics)
            let result = module.localizeImage(baseAddress, width: Int32(width), height: Int32(height), intrinsics: intrinsics_baseAddress)
            
            print("Localization result for image", result)
            
            var poses : [LocalizerResponse.Pose] = []
            for pred in result {
                if Double(pred[12]) < 0.01 {
                    print("Ignoring score ", Double(pred[12]))
                    continue
                }
                
                let rot = Mat3(
                    rows: [
                        [Double(pred[0]),Double(pred[1]),Double(pred[2])],
                        [Double(pred[3]),Double(pred[4]),Double(pred[5])],
                        [Double(pred[6]),Double(pred[7]),Double(pred[8])]
                    ]
                )
            
                let quat = Quat(rot)
                let pos = Point3(Double(pred[9]), Double(pred[10]), Double(pred[11]));
                let score = pred[12];
                
                poses.append(LocalizerResponse.Pose(score:Double(score), rot: Point4(quat.imag.x,quat.imag.y,quat.imag.z,quat.real), pos: pos))
            }
            
            if poses.count > 0 {
                onSuccess(LocalizerResponse(best_poses: poses))
            }
        }
        
        let intrinsics = intrinsics.map { x in Float32(scale) * Float32(x) }
        
        intrinsics.withUnsafeBufferPointer({ buffer_intrinsics in
            buffer.withUnsafeBufferPointer({ buffer in localizeWithRawImage(buffer: buffer, buffer_intrinsics: buffer_intrinsics)})
        })
    }
}

class LocalizationServiceHTTP : LocalizationService {
    let serverURL : String
    
    init(serverURL : String) {
        self.serverURL = serverURL
    }
    
    let boundary = "example.boundary.\(ProcessInfo.processInfo.globallyUniqueString)"
    let fieldName = "upload_image"
    
    var headers: [String: String] {
        return [
            "Content-Type": "multipart/form-data; boundary=\(boundary)",
            "Accept": "application/json"
        ]
    }
    
    var parameters: [String: Any]? {
        return [:]
    }
    
    override func localize(image: UIImage, intrinsics: [Float], onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        let imageData = image.jpegData(compressionQuality: 1)!
        let mimeType = "image/jpeg" //imageData.mimeType!

        let url = URL(string: serverURL+"/localize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers // method: "POST", headers: headers)
        request.httpBody = createHttpBody(binaryData: imageData, mimeType: mimeType)
        
        let session = URLSession(configuration: .default)
        session.dataTask(with: request, completionHandler: jsonDecoderHandler(on_success: onSuccess, on_failure: onFailure)).resume()
    }
    
    private func createHttpBody(binaryData: Data, mimeType: String) -> Data {
        var postContent = "--\(boundary)\r\n"
        let fileName = "\(UUID().uuidString).jpeg"
        postContent += "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
        postContent += "Content-Type: \(mimeType)\r\n\r\n"

        var data = Data()
        guard let postData = postContent.data(using: .utf8) else { return data }
        data.append(postData)
        data.append(binaryData)

        if let parameters = parameters {
            var content = ""
            parameters.forEach {
                content += "\r\n--\(boundary)\r\n"
                content += "Content-Disposition: form-data; name=\"\($0.key)\"\r\n\r\n"
                content += "\($0.value)"
            }
            if let postData = content.data(using: .utf8) { data.append(postData) }
        }

        guard let endData = "\r\n--\(boundary)--\r\n".data(using: .utf8) else { return data }
        data.append(endData)
        return data
    }
}

struct Pose : Equatable {
    var rot : Quat
    var pos : Point3
    
    init(rot: Quat, pos: Point3) {
        self.rot = rot
        self.pos = pos
    }

    static let canon = Quat(angle: Double.pi/2, axis: Point3(1,0,0))
    
    init(from: Transform) {
        self.rot = Pose.canon * Quat(vector: Point4(from.rotation.vector)) * Pose.canon.inverse
        self.pos = Pose.canon.act(Point3(from.translation))
    }
    
    var transform : Transform {
        let rot = Pose.canon.inverse * self.rot * Pose.canon
        let trans = Pose.canon.inverse.act(Point3(self.pos))
        return Transform(scale: simd_float3(1,1,1), rotation: simd_quatf(vector: simd_float4(rot.vector)), translation: simd_float3(trans))
    }
    
    var inverse : Pose {
        return Pose(
            rot: rot.inverse,
            pos: -rot.inverse.act(pos)
        )
    }
    
    func act(_ pos: Point3) -> Point3 {
        return self.rot.act(pos) + self.pos
    }
    
    static func *(p2: Pose, p1: Pose) -> Pose {
        return Pose(
            rot: p2.rot * p1.rot,
            pos: p2.rot.act(p1.pos) + p2.pos
        )
    }
}

// Quaternion from orthogonal basis


class LocalizerSession : ObservableObject {
    var particles : [Particle] = []
    var old_particles : [Particle] = []
    @Published var public_particles : [Pose] = []
    
    private weak var arView : ARView? = nil
    var intrinsics : [Float] = []
    var localizerService : LocalizationService

    var buildingService : BuildingService
    @Published var pose: Pose? = nil
    
    private var last_odometry_pose : Pose = Pose(rot: Quat.identity, pos: Point3())
    private var last_odometry_timestamp : TimeInterval = -1
    private var odometry_timer : Timer? = nil
    
    var std_odometry_pos : Double = 2.0
    var std_odometry_rot : Double = 0.2
    
    var std_loc_pos : Double = 2.0
    var std_loc_rot : Double = 0.3
    
    var std_noise_pos : Double = 0.5
    var std_noise_rot : Double = 0.1
    
    var std_initial_pos : Double = 20
    var std_initial_rot : Double = Double.pi
    
    var num_particles : Int = 3000
    
    var regen_particles_thresh : Double = 3
    
    var imu_update_interval : Double
    
    struct Particle {
        var trans : Point2
        var rel_heading : Double
        var weight : Double
    }
    
    func setArView(arView: ARView) {
        self.arView = arView
    }
    
    func generateGaussian() -> Double {
        // Generate two uniformly distributed random numbers between 0 and 1
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        
        // Apply the Box-Muller transform
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        // z1 can also be used for another normally distributed random number
        // let z1 = sqrt(-2.0 * log(u1)) * sin(2.0 * .pi * u2)
        
        // Scale and shift the result to fit the desired mean and standard deviation
        return z0
    }
    
    func quatHeading(_ q: Quat) -> Double {
        let p3 = q.act(Point3(x: 1.0, y: 0, z: 0))
        let p2 = Point2(x: p3.x, y: p3.y)
        return atan2(p2.y, p2.x)
    }
            
    init(localizationService : LocalizationService, buildingService: BuildingService, imu_update_interval : Double = 1.0/15) {
        self.imu_update_interval = imu_update_interval
        self.localizerService = localizationService
        self.buildingService = buildingService
        self.pose = Pose(rot: Quat.identity, pos: Point3(x:-13.8121, y:12.7905, z:0.9935))
        //self.spawn_particles(pose_weights: [1.0], poses: [pose!], std_initial_rot: std_initial_rot, std_initial_pos: std_initial_pos)
        
        odometry_timer = Timer.scheduledTimer(timeInterval: imu_update_interval, target: self, selector: #selector(self.update_odometry_selector), userInfo: nil, repeats: true)
        
        self.buildingService.loadFloormap(floor: "E", on_success: process_walkable, on_failure: {e in })
    }
    
    func arkit_to_world() -> Pose {
        guard let pose = self.pose else { return Pose(rot: Quat.identity, pos: Point3()) }
        return pose * last_odometry_pose.inverse
    }
    
    func world_to_arkit() -> Pose {
        guard let pose = self.pose else { return Pose(rot: Quat.identity, pos: Point3()) }
        return last_odometry_pose * pose.inverse
    }
    
    func particle_to_pose(p: Particle) -> Pose {
        let pose = last_odometry_pose;
        let rel_rot = Quat(angle: p.rel_heading, axis: Point3(0,0,1))
        return Pose(rot: rel_rot * pose.rot, pos: Point3(x:p.trans.x,y:p.trans.y,z:last_odometry_pose.pos.z))
    }
    
    func spawn_particles(pose_weights: [Double], poses: [Pose], std_initial_rot: Double, std_initial_pos: Double) {
        self.particles = []
        for i in 0..<num_particles {
            var r = Double.random(in: 0..<1)
            var idx = 0
            while idx < poses.count && r > pose_weights[idx] {
                r -= pose_weights[idx]
                idx += 1
            }
            let pose = poses[min(idx, poses.count-1)]
            
            let rel_heading = quatHeading(pose.rot) - quatHeading(last_odometry_pose.rot)
            let particle = Particle(
                trans: Point2(pose.pos.x,pose.pos.y) + std_initial_pos*Point2(generateGaussian(), generateGaussian()),
                rel_heading: rel_heading,
                weight: 1.0 / Double(num_particles)
            )
            
            let pose_p = particle_to_pose(p: particle)
            particles.append(particle)
        }
        
        self.old_particles = self.particles.map { x in x }
        self.public_particles = self.old_particles.map(particle_to_pose)
    }
    
    @objc func update_odometry_selector() {
        DispatchQueue.main.async {
            self.update_odometry()
        }
    }
    
    func update_odometry() {
        guard let arView = self.arView
        else { return }
            
        let transform = arView.cameraTransform
        
        
        let canon = Quat(angle: Double.pi/2, axis: Point3(1,0,0))
        let odometry_pose = Pose(from: transform)
        /*print("BASIS")
        print(odometry_pose.rot.act(Point3(1,0,0)))
        print(odometry_pose.rot.act(Point3(0,1,0)))
        print(odometry_pose.rot.act(Point3(0,0,1)))*/
        
        let timestamp = NSDate().timeIntervalSince1970
        if last_odometry_timestamp == -1 {
            last_odometry_timestamp = timestamp
            last_odometry_pose = odometry_pose
        }
        let dt = min(timestamp - last_odometry_timestamp, 2*imu_update_interval) // Prevent excessive dt (e.g after breakpoint from blowing up particles)
        
        let odometry_delta = Pose(rot: (odometry_pose.rot * last_odometry_pose.rot.inverse).normalized, pos: odometry_pose.pos - last_odometry_pose.pos)
        
        last_odometry_pose = odometry_pose
        last_odometry_timestamp = timestamp
        
        if self.particles.isEmpty {
            if var pose = self.pose {
                pose.pos += 10*odometry_delta.pos
                pose.rot = last_odometry_pose.rot; // odometry_delta.rot * pose.rot
                self.pose = pose
            }
        }
        
        propagate(odometry_delta: odometry_delta, dt: dt)
        update_belief()
        //print("IMU Pose", imu_pose.pos, imu_pose.rot)
    }
    
    func propagate(odometry_delta: Pose, dt: Double) {
        for i in 0..<particles.count {
            var p = particles[i]
            let rand_rot : Double = dt*std_noise_rot*generateGaussian()
            let rand_pos = Point2(
                x: dt*std_noise_pos*generateGaussian(),
                y: dt*std_noise_pos*generateGaussian()
            )
            
            let pos_delta = Quat(angle: p.rel_heading, axis: Point3(0,0,1)).act(odometry_delta.pos)
            
            p.rel_heading += rand_rot
            p.trans += Point2(pos_delta.x,pos_delta.y) + rand_pos;
            
            particles[i] = p
        }
    }
    
    func update_belief() {
        if particles.count == 0 { return }
        obstacle_step()
        resample_particles()
        update_pose()
    }
    
    func update_pose() {
        var sum_weight = 0.0;
        var avg_pos = Point2(x: 0,y: 0)
        var avg_heading = Point2(x: 0, y: 0)
        
        for p in particles {
            sum_weight += p.weight;
            avg_pos += p.trans*p.weight;
            
            
            avg_heading += Point2(cos(p.rel_heading), sin(p.rel_heading)) * p.weight
        }
        avg_pos /= sum_weight;
        avg_heading /= sum_weight;
        
        let heading = atan2(avg_heading.y, avg_heading.x)
        self.pose = particle_to_pose(p: Particle(trans: avg_pos, rel_heading: heading, weight: 1.0))
    }
    
    func resample_particles() {
        var cum_weight = 0.0;
        var cum_weights : [Double] = []
        for p in particles {
            cum_weights.append(cum_weight)
            cum_weight += p.weight;
        }
        cum_weights = cum_weights.map { x in x / cum_weight }
        
        var new_particles : [Particle] = []
        for i in 0..<particles.count {
            let r = Double.random(in: 0.0..<1.0)
            var start = 0
            var end = particles.count
            
            while start < end {
                let mid = (start+end) / 2
                let w = cum_weights[mid]
                if r < w { end = mid }
                else { start = mid+1 }
            }
            
            let idx0 = max(0,end-1)
            let idx1 = min(idx0,end-1)
            
            var particle0 = particles[idx0]
            var particle1 = particles[idx1]
            
            let res = idx0==idx1 ? 1 : (r-cum_weights[idx0])/(cum_weights[idx1]-cum_weights[idx0]);
            
            var particle = Particle(
                trans: (1-res)*particle0.trans + res*particle1.trans,
                rel_heading: (1-res)*particle0.rel_heading + res*particle1.rel_heading,
                weight: 1.0/Double(particles.count))
            new_particles.append(particle)
        }
        
        self.public_particles = new_particles.map(particle_to_pose)
        old_particles = particles
        particles = new_particles
    }
    
    struct Walkable_Area {
        var min : Point2
        var max : Point2
        var dx : Point2
        var walkable_area : [[Point2]]
        var grid_walkable_index : [[[Int]]]
        
        func to_grid(point: Point2) -> simd_int2 {
            let grid = (point - min) / dx
            return simd_int2(x: Int32(Int(grid.x)), y: Int32(Int(grid.y)))
        }
        
        func is_walkable(point: Point2) -> Bool {
            for polygon in walkable_area {
                if(isPointInside(point: point, polygon: polygon)) {
                    return true
                }
            }
            return false
            
            let grid = to_grid(point: point)
            if grid.x < 0 || grid.x >= walkable_area.count || grid.y < 0 || grid.y >= walkable_area.count { return false }
            
            for k in grid_walkable_index[Int(grid.y)][Int(grid.x)] {
                let polygon = walkable_area[k]
                if(isPointInside(point: point, polygon: polygon)) {
                    return true
                }
            }

            return false
        }

        // todo: add wall information
        func intersects_wall(a: Point2, b: Point2) -> Bool {
            return !(is_walkable(point: a) && is_walkable(point: b))
        }
    }
    
    var walkable_area : Walkable_Area?
    
    func process_walkable(floor: Floor) {
        let grid_dim = 10
        
        var grid : [[[Int]]] = []
        let dx = (floor.max - floor.min) / Double(grid_dim)
        
        for i in 0..<grid_dim {
            var row : [[Int]] = []
            for j in 0..<grid_dim {
                let min = floor.min + Double(grid_dim)*Point2(x:Double(j),y:Double(i))
                let max = floor.max + Double(grid_dim)*Point2(x:Double(j+1),y:Double(i+1))
        
                var overlap_contours : [Int] = []
                for k in 0..<floor.walkable_areas.count {
                    var overlap = false
                    for l in floor.walkable_areas[i] {
                        if min.x <= l.x && min.y <= l.y && l.x <= max.x && l.y <= max.y {
                            overlap = true
                            break
                        }
                    }
                    if overlap {
                        overlap_contours.append(k)
                    }
                }
                row.append(overlap_contours)
            }
            grid.append(row)
        }
        
        self.walkable_area = Walkable_Area(min: floor.min, max: floor.max, dx: dx, walkable_area: floor.walkable_areas, grid_walkable_index: grid)
    }
    
    func obstacle_step() {
        guard let walkable_area = self.walkable_area
        else { return }
            
        //return
            
        for i in 0..<particles.count {
            let p1 = particles[i]
            var prob = 0.0;
            
            /*for p2 in old_particles {
                let pos1 = Point2(x: p1.pose.pos.x, y: p1.pose.pos.y)
                let pos2 = Point2(x: p2.pose.pos.y, y: p2.pose.pos.y)
                
                if !walkable_area.intersects_wall(a: pos1, b: pos2) {
                    prob += p2.weight
                }
            }*/
            let pose = particle_to_pose(p: p1)
            
            if(walkable_area.is_walkable(point: Point2(x:pose.pos.x,y:pose.pos.y))) {
                prob = 1
            } else {
                prob = 0.3
            }
            
            let new_weight = p1.weight * prob
            particles[i].weight = new_weight
        }
    }
    
    func gaussian_loss(delta: Double, std: Double) -> Double {
        return 1.0/(std*sqrt(2*Double.pi))*exp(-pow(delta/std, 2))
    }
    
    func localize_step(pose_weights: [Double], poses: [Pose]) {
        for i in 0..<particles.count {
            let p1 = particle_to_pose(p: particles[i])
            
            var prob = 0.0
            for j in 0..<poses.count {
                let weight = pose_weights[j]
                let p2 = poses[j]
                
                let delta_pos = simd_length((p2.pos - p1.pos))
                let delta_rot = abs((p2.rot * p1.rot.inverse).normalized.angle)
            
                prob += weight * gaussian_loss(delta: delta_pos, std: std_odometry_pos) * gaussian_loss(delta: delta_rot, std: std_odometry_rot)
            }
            
            let new_weight = particles[i].weight * prob
            particles[i].weight = new_weight
        }
    }
    
    func localize(on_success: @escaping (Pose) -> Void = { p in }, on_failure: @escaping (String)->Void = { e in print(e) }) {
        print("Localizing!")
        
        #if targetEnvironment(simulator)
        print("target environemt is simulator")
        let image = UIImage(systemName: "house.fill")!
        #else
        guard let img = self.arView?.session.currentFrame?.capturedImage else {
            print("Could not acquire image")
            return
        }
        let ciimg = CIImage(cvImageBuffer: img)
        let image = UIImage(ciImage: ciimg)
        #endif
        
        func on_localize(data: LocalizerResponse) {
            DispatchQueue.main.async {
                var curr_pose = Pose(rot: Quat.identity, pos: Point3(1000,1000,1000))
                if let pose = self.pose {
                    curr_pose = pose
                }
            
                var poses : [Pose] = []
                var weights : [Double] = []
            
                var min_dist = 1000.0
                
                for pose in data.best_poses {
                    let p = Pose(
                        rot:Quat(ix: pose.rot.x, iy: pose.rot.y, iz: pose.rot.z, r: pose.rot.w),
                        pos:pose.pos
                    )
                    poses.append(p)
                    weights.append(pose.score)
                    min_dist = min(min_dist, simd_length(p.pos - curr_pose.pos))
                }
                    
                print("Applying Localize step")
                
                let regen = self.particles.count == 0 || min_dist > self.regen_particles_thresh
                if regen {
                    print("Spawning particles")
                    self.spawn_particles(pose_weights: weights, poses: poses, std_initial_rot: self.std_loc_rot, std_initial_pos: self.std_loc_pos)
                    self.update_pose()
                } else {
                    self.localize_step(pose_weights: weights, poses: poses)
                    self.update_belief()
                }
                
                if let pose = self.pose { on_success(pose) }
                else { on_failure("Unexpected error") }
            }
        }
        
        self.localizerService.localize(image: image, intrinsics: intrinsics, onSuccess: on_localize, onFailure: on_failure)
    }
}
