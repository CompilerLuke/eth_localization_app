import Foundation
import simd

typealias Mat2 = simd_double2x2
typealias Mat3 = simd_double3x3
typealias Point2 = simd_double2
typealias Point3 = simd_double3
typealias Point4 = simd_double4
typealias Quat = simd_quatd

extension Quat {
    static var identity : Quat {
        Quat(ix:0,iy:0,iz:0,r:1)
    }
}

struct Location : Identifiable, Decodable {
    var id : String { label }
    var label : String
    //var desc : String
    var contour: [Point2]
}

struct Room : Identifiable, Decodable {
    var id : String { label }
    var label : String
    //var desc : String = ""
    var contour: [Point2]
    //var type : Int
}


struct Floor : Decodable {
    var min: Point2
    var max: Point2
    var outline: [Point2]
    var locations: [Room]
    var walkable_areas: [[Point2]] 
}

struct Building : Decodable {
    var floors: [Floor]
}
