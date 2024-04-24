import Foundation

struct Location : Identifiable, Decodable {
    var id : Int
    var label : String
    var desc : String
    var contour: [Point2]
}

struct Room : Identifiable, Decodable {
    var id : Int = 0
    var label : String
    var desc : String
    var contour: [Point2]
    var type : Int
}

struct Floor : Decodable {
    var min: Point2
    var max: Point2
    var outline: [Point2]
    var locations: [Room]
}

struct Building : Decodable {
    var floors: [Floor]
}
