//
//  NavigationSession.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import Foundation
import SwiftGraph

struct NavigationNode : Decodable {
    var pos : [Point3]
}

struct NavigationPath : Decodable {
    var path : [NavigationNode]
}

protocol NavigationService {
    func navigate(startPoint: Point3, endPoint: Point3, onSuccess: @escaping (NavigationPath) -> Void, onFailure: @escaping (String) -> Void)
}

class NavigationServiceDevice : NavigationService {
    var buildingService : BuildingService
    
    init(buildingService : BuildingService) {
        self.buildingService = buildingService
    }
    
    func navigate(startPoint: Point3, endPoint: Point3, onSuccess: @escaping (NavigationPath) -> Void, onFailure: @escaping (String) -> Void) {
        self.buildingService.loadFloormap(floor: "E", on_success: { floor in
            self.navigateFloor(floor: floor, startPoint: startPoint, endPoint: endPoint, onSuccess: onSuccess, onFailure: onFailure)
        }, on_failure: onFailure)
    }
    
    func navigateFloor(floor: Floor, startPoint: Point3, endPoint: Point3, onSuccess: @escaping (NavigationPath) -> Void, onFailure: @escaping (String) -> Void) {
        let graph = createGraph(from: floor, width: 100, height: 100)
        var startPoint = Point2(startPoint.x, startPoint.y)
        startPoint = findNearestPoint(from: startPoint, in: graph)!
        
        guard let endPoint = findNearestPoint(from: Point2(endPoint.x,endPoint.y), in: graph)
        else {
            DispatchQueue.main.async {
                onFailure("Could not find end point")
            }
            return
        }
        
        //print(graph.description)
        let (distances, pathDict) = graph.dijkstra(root: startPoint, startDistance: 0)
        //print (pathDict)
        var nearestPoint: Point2? = nil
        var minDistance = Double.greatestFiniteMagnitude
        
        for (vertex, _) in pathDict {
            let currentPoint = graph.vertexAtIndex(vertex)
            let currentDistance = distance(from: currentPoint, to: endPoint)
            if currentDistance < minDistance {
                minDistance = currentDistance
                nearestPoint = currentPoint
            }
        }
        
        if let nearestPoint = nearestPoint {
            let endPointIndex = graph.indexOfVertex(nearestPoint)
            let path: [WeightedEdge<Double>] = pathDictToPath(from: graph.indexOfVertex(startPoint)!, to: endPointIndex!, pathDict: pathDict)
            let stops: [Point2] = graph.edgesToVertices(edges: path)
                
            DispatchQueue.main.async {
                onSuccess(NavigationPath(stops: stops.map({loc in NavigationNode(pos: Point3(loc.x,loc.y,0))})))
            }
        }
    }
}

class NavigationServiceHTTP : NavigationService {
    let serverURL : String
    
    init(serverURL: String) {
        self.serverURL = serverURL
    }
    
    func navigate(startPoint: Point3, endPoint: Point3, onSuccess: @escaping (NavigationPath) -> Void, onFailure: @escaping (String) -> Void) {
        getRequest(path: "\(serverURL)navigate?srcPosition=\(startPoint.x),\(startPoint.y),\(startPoint.z)&dstPosition=\(endPoint.x),\(endPoint.y),\(endPoint.z)", on_success: onSuccess, on_failure: onFailure)
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
        guard let position = localizerSession.pose?.pos
        else {
            print("Not yet localized")
            return
        }
        
        navigate(srcPosition: position, dstLocation: dstLocation)
    }
}
