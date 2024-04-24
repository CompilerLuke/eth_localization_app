//
//  MapService.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import Foundation

class BuildingService : ObservableObject {
    var serverURL: String
    var building : Int
    
    init(serverURL: String, building: Int) {
        self.serverURL = serverURL
        self.building = building
    }
    
    func setBuilding(building : Int) {
        self.building = building
    }
    
    func loadFloormap(floor: String, on_success: @escaping (Floor) -> (), on_failure: @escaping (String) -> ()) {
        getRequest(path: "\(serverURL)/map?building=\(building)", on_success: on_success, on_failure: on_failure)
    }
    
    func queryLocations(name: String, on_success: @escaping ([Location]) -> (), on_failure: @escaping (String) -> ()) {
        struct Result : Decodable {
            var locations : [Location]
        }
        
        func get_locations(result: Result) {
            on_success(result.locations)
        }
        
        getRequest(path: "\(serverURL)map?building=\(building)&matches=\(name)", on_success: get_locations, on_failure: on_failure)
    }
}
