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

class NavigationSession : ObservableObject {
    enum Mode {
        case notarget
        case destination(Int)
    }
    
    var mode : Mode
    var serverURL : String
    var localizerSession : LocalizerSession
    
    @Published var nodePath : [NavigationNode]
    
    init(serverURL : String, localizerSession: LocalizerSession) {
        self.serverURL = serverURL
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
        
        getRequest(path: "\(serverURL)navigate?srcPosition=\(srcPosition.x),\(srcPosition.y),\(srcPosition.z)&dstLocation=\(dstLocation)", on_success: onSuccess, on_failure: onFailure)
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
