//
//  GraphView.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 20/05/24.
//
import SwiftGraph
import Foundation
import SwiftUI
import simd

class Node {
    var position: (Double, Double)
    
    init(position: (Double, Double)) {
        self.position = position
    }
}


// Function to check if a point is inside a polygon
func isPointInsidePolygon(point: Point2, polygon: [Point2]) -> Bool {
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

// Function to create a graph from walkable areas
func createGraph(from floor: Floor, width: Int, height: Int) -> WeightedGraph<Point2, Double> {
    let graph = WeightedGraph<Point2, Double>()
    
    var nodes: [[Point2?]] = Array(repeating: Array(repeating: nil, count: width), count: height)
    
    let delta = (floor.max - floor.min) / Point2(Double(width),Double(height))
    
    for i in 0..<height {
        for j in 0..<width {
            let point = Point2(Double(j) * delta.x + floor.min.x, Double(i) * delta.y + floor.min.y)
            let inside = floor.walkable_areas.contains { area in
                isPointInsidePolygon(point: point, polygon: area.map { Point2($0[0], $0[1]) })
            }
            if inside {
                nodes[i][j] = point
                graph.addVertex(point)
            }
        }
    }
    
    for i in 0..<height {
        for j in 0..<width {
            guard let node = nodes[i][j] else { continue }
            
            if i > 0, let aboveNode = nodes[i-1][j] {
                let weight = distance(from: node, to: aboveNode)
                graph.addEdge(from: node, to: aboveNode, weight: weight, directed: false)
            }
            if i < height - 1, let belowNode = nodes[i+1][j] {
                let weight = distance(from: node, to: belowNode)
                graph.addEdge(from: node, to: belowNode, weight: weight, directed: false)
            }
            if j > 0, let leftNode = nodes[i][j-1] {
                let weight = distance(from: node, to: leftNode)
                graph.addEdge(from: node, to: leftNode, weight: weight, directed: false)
            }
            if j < width - 1, let rightNode = nodes[i][j+1] {
                let weight = distance(from: node, to: rightNode)
                graph.addEdge(from: node, to: rightNode, weight: weight, directed: false)
            }
        }
    }
   
    return graph
}

// Function to calculate the Euclidean distance between two points
func distance(from: Point2, to: Point2) -> Double {
    return sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2))
}

func findNearestPoint(from point: Point2, in graph: WeightedGraph<Point2, Double>) -> Point2? {
    guard !graph.vertices.isEmpty else {
        return nil
    }

    var nearestPoint = graph.vertices[0]
    var minDistance = distance(from: point, to: nearestPoint)

    for vertex in graph.vertices {
        let currentDistance = distance(from: point, to: vertex)
        if currentDistance < minDistance {
            nearestPoint = vertex
            minDistance = currentDistance
        }
    }

    return nearestPoint
}




