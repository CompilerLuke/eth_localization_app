import Foundation


class BuildingService : ObservableObject {
    func loadFloormap(floor: String, on_success: @escaping (Floor) -> (), on_failure: @escaping (String) -> ()) {
            assert(false)
        }
    func queryLocations(name: String, on_success: @escaping ([Location]) -> (), on_failure: @escaping (String) -> ()) -> Void {
        assert(false);
    }
}

class BuildingServiceDevice : BuildingService {
    var building : Building?
    
    func loadBuilding(on_success: @escaping (Building) -> (), on_failure: @escaping (String) -> ()) {
        func success(building: Building) {
            self.building = building
            on_success(building)
        }
        
        func failure(err: String) {
            on_failure(err)
        }
        
        if let building = self.building {
            on_success(building)
        } else {
            getLocalJSON(path: "building", on_success: on_success, on_failure: on_failure)
        }
    }
    
    override func loadFloormap(floor: String, on_success: @escaping (Floor) -> (), on_failure: @escaping (String) -> ()) {
        func success(building: Building) {
            self.building = building
            print("Building loaded")
            on_success(building.floors[0])
        }
        
        func failure(err: String) {
            on_failure(err)
        }
        
        loadBuilding(on_success: success, on_failure: failure)
    }
    
    override func queryLocations(name: String, on_success: @escaping (([Location]) -> ()), on_failure: @escaping (String) -> ()) {
    }
}

class BuildingServiceHTTP : BuildingService {
    var serverURL: String
    var building : Int
    
    init(serverURL: String, building: Int) {
        self.serverURL = serverURL
        self.building = building
    }
    
    func setBuilding(building : Int) {
        self.building = building
    }
    
    override func loadFloormap(floor: String, on_success: @escaping (Floor) -> (), on_failure: @escaping (String) -> ()) {
        getRequest(path: "\(serverURL)/map?building=\(building)", on_success: on_success, on_failure: on_failure)
    }
    
    override func queryLocations(name: String, on_success: @escaping ([Location]) -> (), on_failure: @escaping (String) -> ()) {
        struct Result : Decodable {
            var locations : [Location]
        }
        
        func get_locations(result: Result) {
            on_success(result.locations)
        }
        
        getRequest(path: "\(serverURL)map?building=\(building)&matches=\(name)", on_success: get_locations, on_failure: on_failure)
    }
}

func isPointInside(point: Point2, polygon: [Point2]) -> Bool {
     var j = polygon.count - 1
     var oddNodes = false

     for i in 0..<polygon.count {
         if (polygon[i].y < point.y && polygon[j].y >= point.y || polygon[j].y < point.y && polygon[i].y >= point.y) {
             if (polygon[i].x + (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) * (polygon[j].x - polygon[i].x) < point.x) {
                 oddNodes = !oddNodes
             }
         }
         j = i
     }
     return oddNodes
}

// https://forum.unity.com/threads/line-intersection.17384/#post-4442284
func lineIntersects(a0: Point2, b0: Point2, a1: Point2, b1: Point2) -> Bool {
    let a = b0 - a0;
    let b = a1 - b1;
    let c = a0 - b0;

    let alphaNumerator = b.y * c.x - b.x * c.y;
    let betaNumerator  = a.x * c.y - a.y * c.x;
    let denominator    = a.y * b.x - a.x * b.y;

    if (denominator == 0) {
     return false;
    } else if (denominator > 0) {
    if (alphaNumerator < 0 || alphaNumerator > denominator || betaNumerator < 0 || betaNumerator > denominator) {
         return false;
     }
    } else if (alphaNumerator > 0 || alphaNumerator < denominator || betaNumerator > 0 || betaNumerator < denominator) {
     return false;
    }
    return true;
}

func lineIntersects(a: Point2, b: Point2, polygon: [Point2]) -> Bool {
    for i in 0...polygon.count {
        let a1 = polygon[i]
        let b1 = polygon[(i+1)%polygon.count]
        if(lineIntersects(a0: a, b0: b, a1: a1, b1: b1)) {
            return true
        }
    }
    return false
}
