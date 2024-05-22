//
//  LocalizationMapOverlay.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 22/05/24.
//

import SwiftUI
import simd
import SwiftGraph


// MapTheme definition

struct LocalizationMapOverlayView: View {
    @EnvironmentObject var localizerSession: LocalizerSession
    var theme: MapTheme = MapTheme()
    var floor: Floor?
    @State var location: Point3?
    var world_to_image: Mat3
    
    @State var scale: CGFloat = 1.0
    @State var base_scale: CGFloat = 1.0
    @State var offset_base: Point2 = Point2(x: 0, y: 0)
    @State var offset: Point2 = Point2(x: 0, y: 0)
    @State var size: CGSize = CGSize(width: 1, height: 1)
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                print("Canvas size: \(size)") // Debug statement
                if size != self.size {
                    DispatchQueue.main.async { self.size = size }
                }
                let size = Point2(x: size.width, y: size.height)
                let size_a = max(size.x, size.y)
                let scale_to_rect = Mat3([size_a, 0, 0], [0, -size_a, 0], [0, size.y, 1])
                let viewpoint = Mat3([scale * base_scale, 0, (offset.x + offset_base.x)], [0, scale * base_scale, (offset.y + offset_base.y)], [0, 0, 1]).transpose
                let trans = viewpoint * scale_to_rect * world_to_image
                
                if let fl = floor {
                    RenderFloor(context: context, theme: theme, trans: trans, floor: fl)
                }
                
                if let loc = location {
                    RenderLocationIndicator(context: context, theme: theme, trans: trans, position: Point2(loc.x, loc.y), color: Color.green)
                }
            }
            .background(theme.background)
            .gesture(DragGesture().onChanged { value in offset = Point2(x: value.translation.width, y: value.translation.height) }
                .onEnded { _ in offset_base += offset; offset = Point2(x: 0, y: 0) })
            .gesture(MagnificationGesture().onChanged { newScale in
                let center = Point2(size.width / 2, size.height / 2)
                offset_base = center - newScale / scale * (center - offset_base)
                scale = newScale
            }.onEnded { _ in base_scale *= scale; scale = 1.0 })
            
            // Navigation bar with buttons at the bottom
            VStack {
                HStack{
                    Spacer()
                    Spacer()
                    VStack {
                        Spacer()
                        Button(action: {
                            centerMapOnCentroid()
                        }) {
                            VStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title)
                                
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white.opacity(0.5))
                            
                          
                        }
                        
                        Button(action: {
                            scale *= 1.1
                            base_scale *= 1.1
                        }) {
                            VStack {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title)
                                
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white.opacity(0.5))
                            
                            
                        
                        }
                        
                        Button(action: {
                            scale *= 0.9
                            base_scale *= 0.9
                        }) {
                            VStack {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title)
                                
                                
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white.opacity(0.5))
                           
                            
                        }
                        
                        Button(action: {
                            localizerSession.localize()
                        }) {
                            VStack {
                                Image(systemName: "location.circle")
                                    .font(.title)
                                
                            }
                            .foregroundColor(.white)
                            .padding()
                            
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                    }
                    
            
                }
            }
        }
        .onAppear {
            if let initialLocation = localizerSession.position {
                location = initialLocation
            }
        }
        .onChange(of: localizerSession.position) { newPosition in
            location = newPosition
        }
    }
    
    func centerMapOnCentroid() {
        print("hello1")
        if let loc = location {
            print("hello2")
            let centroid = Point2(loc.x, loc.y)
            let size = Point2(x: self.size.width, y: self.size.height)
            let size_a = max(size.x, size.y)
            let scale_to_rect = Mat3([size_a, 0, 0], [0, -size_a, 0], [0, size.y, 1])
            let viewpoint = Mat3([scale * base_scale, 0, (offset.x + offset_base.x)], [0, scale * base_scale, (offset.y + offset_base.y)], [0, 0, 1]).transpose
            let trans = viewpoint * scale_to_rect * world_to_image
            
            // Transform the centroid to the view coordinates
            let centroidInView = apply_transform(trans, centroid)
            
            // Calculate the new offset to center the centroid in the view
            offset_base = Point2(x: size.x / 2 - centroidInView.x, y: size.y / 2 - centroidInView.y)
            
            print("hello3")
        }
    }
}

struct LocalizationMapOverlay: View {
    @EnvironmentObject var buildingService: BuildingService
    @State private var isLoading: Bool = false
    @State private var floor: Floor?
    @State private var world_to_image: Mat3 = Mat3(diagonal: Point3(1, 1, 1))
    @EnvironmentObject var localizerSession: LocalizerSession
    
    func loadMap() {
        isLoading = true
        buildingService.loadFloormap(floor: "G", on_success: { floor in
            let max = floor.outline.reduce(Point2(-Double.infinity, -Double.infinity), simd_max)
            let min = floor.outline.reduce(Point2(Double.infinity, Double.infinity), simd_min)
            let image_to_world: Mat3 = Mat3(
                [(max.x - min.x), 0, -min.x],
                [0, (max.y - min.y), -min.y],
                [0, 0, 1]
            ).transpose

            let world_to_image = simd_inverse(image_to_world)
            
            DispatchQueue.main.async {
                self.floor = floor
                self.world_to_image = world_to_image
                self.isLoading = false
            }
        }, on_failure: { error in
            self.isLoading = false
            print("Failed to load floor map: \(error)")
        })
    }
    
    var body: some View {
        NavigationView {
            LocalizationMapOverlayView(theme: MapTheme(), floor: floor, location: localizerSession.position, world_to_image: world_to_image)
                .navigationBarTitle("", displayMode: .inline)
                .onAppear {
                    loadMap()
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarTitleDisplayMode(.inline)
    }
}
