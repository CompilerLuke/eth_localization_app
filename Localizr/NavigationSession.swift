//
//  NavigationSession.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import Foundation

struct NavigationNode : Decodable {
    var pos: Point3
}

protocol NavigationService {
    func navigate(srcPosition: Point3, dstLocation: Int, onSuccess: @escaping ([NavigationNode]) -> Void, onFailure: @escaping (String) -> Void)
}

class NavigationServiceDevice : NavigationService {
    func navigate(srcPosition: Point3, dstLocation: Int, onSuccess: @escaping ([NavigationNode]) -> Void, onFailure: @escaping (String) -> Void) {
        
    }
}

class NavigationServiceHTTP : NavigationService {
    let serverURL : String
    
    init(serverURL: String) {
        self.serverURL = serverURL
    }
    
    func navigate(srcPosition: Point3, dstLocation: Int, onSuccess: @escaping ([NavigationNode]) -> Void, onFailure: @escaping (String) -> Void) {
        getRequest(path: "\(serverURL)navigate?srcPosition=\(srcPosition.x),\(srcPosition.y),\(srcPosition.z)&dstLocation=\(dstLocation)", on_success: onSuccess, on_failure: onFailure)
    }
}

class NavigationSession : ObservableObject {
    enum Mode {
        case notarget
        case destination(Int)
    }
    
    var mode : Mode
    var navigationService : NavigationService
    var localizerSession : LocalizerSession
    
    @Published var nodePath : [NavigationNode]
    
    init(navigationService : NavigationService, localizerSession: LocalizerSession) {
        self.navigationService = navigationService
        self.mode = Mode.notarget
        self.localizerSession = localizerSession
        self.nodePath = []
    }
    
    func navigate(srcPosition: Point3, dstLocation: Int) {
        self.mode = Mode.destination(dstLocation)
        
        func onSuccess(nodePath: [NavigationNode]) {
            self.nodePath = nodePath
        }
        
        func onFailure(err: String) {
            
        }
        
        navigationService.navigate(srcPosition: srcPosition, dstLocation: dstLocation, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func navigate(dstLocation: Int) {
        guard let position = localizerSession.position
        else {
            print("Not yet localized")
            return
        }
        
        navigate(srcPosition: position, dstLocation: dstLocation)
    }
}
