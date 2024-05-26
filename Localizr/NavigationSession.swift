//
//  NavigationSession.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import Foundation
import SwiftGraph

struct NavigationNode : Decodable {
    var pos : Point3
}

struct NavigationPath : Decodable {
    var path : [NavigationNode]
}

protocol NavigationService {
    func navigate(startPoint: Point3, endPoint: Point3, onSuccess: @escaping (NavigationPath) -> Void, onFailure: @escaping (String) -> Void)
}

class NavigationServiceDevice : NavigationService {
    var buildingService : BuildingService
    var graph : WeightedGraph<Point2, Double>?
    
    init(buildingService : BuildingService) {
        self.buildingService = buildingService
        
        self.buildingService.loadFloormap(floor: "", on_success: createGraph, on_failure: { e in print("Failed to load floor") })
    }
    
    func createGraph(floor: Floor) {
        self.graph = localizr.createGraph(from: floor, width: 300, height: 300)
    }
    
    func navigate(startPoint: Point3, endPoint: Point3, onSuccess: @escaping (NavigationPath) -> Void, onFailure: @escaping (String) -> Void) {
        guard let graph = self.graph else { onFailure("Missing graph"); return }
        
        var startPoint = Point2(startPoint.x, startPoint.y)
        startPoint = findNearestPoint(from: startPoint, in: graph)!
        
        guard let endPoint = findNearestPoint(from: Point2(endPoint.x,endPoint.y), in: graph)
        else {
            onFailure("Could not find end point")
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
                
            onSuccess(NavigationPath(path: stops.map({loc in NavigationNode(pos: Point3(loc.x,loc.y,0))})))
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
        case calculatingPath(String)
        case destinationRoom(String, Point3)
    }
    
    var mode : Mode
    var navigationService : NavigationService
    var buildingService : BuildingService
    var localizerSession : LocalizerSession
    
    @Published var nodePath : NavigationPath?
    
    init(navigationService : NavigationService, localizerSession: LocalizerSession, buildingService : BuildingService) {
        self.navigationService = navigationService
        self.mode = Mode.notarget
        self.localizerSession = localizerSession
        self.nodePath = nil
        self.buildingService = buildingService
    }
    
    func navigate(startPoint: Point3, room: String) {
        self.mode = .calculatingPath(room)
        
        buildingService.loadFloormap(floor: "", on_success: {floor in
            let roomContour = floor.locations.first(where: { $0.label == room })?.contour ?? []
            let endPoint = calculateCentroid(points: roomContour)
            let endPoint3 = Point3(endPoint.x,endPoint.y,0)
            
            func onSuccess(nodePath: NavigationPath) {
                self.mode = Mode.destinationRoom(room, endPoint3)
                self.nodePath = nodePath
            }
            
            func onFailure(err: String) {}
            
            self.navigationService.navigate(startPoint: startPoint, endPoint: endPoint3, onSuccess: onSuccess, onFailure: onFailure)
        }, on_failure: {err in})
    }
    
    func update(startPoint: Point3) {
        let mode = self.mode
        if case let .destinationRoom(room, endPoint) = self.mode {
            self.mode = .calculatingPath(room)
            
            self.navigationService.navigate(startPoint: startPoint, endPoint: endPoint, onSuccess: { path in
                self.mode = mode
                self.nodePath = path
            }, onFailure: {err in self.mode = mode })
        }
    }
}
