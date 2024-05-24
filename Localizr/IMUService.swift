import Foundation
import CoreMotion
import simd

class IMUService : ObservableObject {
    var queue : OperationQueue
    var motion : CMMotionManager
    
    @Published var acceleration_raw : Point3 = Point3()
    @Published var acceleration : Point3 = Point3()
    @Published var position : Point3 = Point3()
    @Published var velocity : Point3 = Point3()
    @Published var rotation : Quat = Quat.identity
    
    var pose : Pose {
        Pose(rot: rotation, pos: position)
    }
    
    var vel_damping : Double = 0.5
    var last_update : Double = -1
    
    var update_interval = 1.0 / 50.0
 
    init() {
        queue = OperationQueue()
        motion = CMMotionManager()
        motion.deviceMotionUpdateInterval = update_interval
        motion.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: queue, withHandler: {(motion: CMDeviceMotion?, _ err: (any Error)?) in
            DispatchQueue.main.async {
                self.update(motion: motion,err: err)
            }
        })
    }
    
    func update(motion: CMDeviceMotion?, err: (any Error)?) {
        guard let motion = motion else { return }
        
        let quat = motion.attitude.quaternion
        var rotation = Quat(ix: quat.x, iy: quat.y, iz: quat.z, r: quat.w).normalized
        
        let timestamp = NSDate.now.timeIntervalSince1970
        if(last_update == -1) { last_update = timestamp }
        let dt = timestamp - last_update
        
        let vec = motion.userAcceleration
        acceleration = rotation.act(9.8*Point3(x: vec.x, y: vec.y, z: vec.z))
        
        velocity -= vel_damping * velocity * dt
        velocity += dt*acceleration
        position += dt*velocity
        self.rotation = rotation * Quat(angle: -Double.pi/2, axis: Point3(1,0,0))
        last_update = timestamp
    }
}

import SwiftUI
struct IMUView : View {
    @EnvironmentObject var imu : IMUService
    
    struct VecView : View {
        var label : String
        var vec : Point3
        
        func format(_ x: Double) -> String {
            return String(format: "%.2f", x)
        }
        
        var body: some View {
            Text("\(label) : x=\(format(vec.x)) y=\(format(vec.y)) z=\(format(vec.z))")
        }
    }
    
    var body: some View {
        let pos = imu.position
        let vel = imu.velocity

        VStack{
            VecView(label: "raw", vec: imu.acceleration)
            VecView(label: "acc", vec: imu.acceleration)
            VecView(label: "pos", vec: pos)
            VecView(label: "vel", vec: vel)
            VecView(label: "x_basis", vec: imu.rotation.act(Point3(1.0,0.0,0.0)))
            VecView(label: "y_basis", vec: imu.rotation.act(Point3(0.0,1.0,0.0)))
            VecView(label: "z_basis", vec: imu.rotation.act(Point3(0.0,0.0,1.0)))
        }
    }
}
