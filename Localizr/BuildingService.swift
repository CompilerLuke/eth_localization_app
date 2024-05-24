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
