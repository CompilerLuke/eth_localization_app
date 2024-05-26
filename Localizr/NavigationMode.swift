//
//  NavigationMode.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 18/05/24.
//

import SwiftUI
import simd
import Foundation
import Combine




enum NavigationModeState : Hashable {
    case viewing
    case navigating
}

struct NavigationMode: View {
    var room: String
    var theme: MapTheme = MapTheme()
    var floor: Floor?
    var path: [Point2] = []
    var world_to_image: Mat3 = Mat3(diagonal: Point3(1, 1, 1))
    
    @EnvironmentObject var localizerSession : LocalizerSession
    @EnvironmentObject var navigationSession : NavigationSession
    @State private var navigationMode: NavigationModeState = .viewing
    
    let overlaySize : [NavigationModeState: CGSize] = [
        NavigationModeState.viewing: CGSize(width: 100, height: 100),
        NavigationModeState.navigating: CGSize(width: 200, height: 400)
    ]
    
    var body: some View {
        ZStack {
            VStack {
                // Card to render the map
                VStack {
                    Text("Destination : \(room)")
                    MapOverlay(mode: navigationMode).frame(height: 600)
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(10.0)
                
                Spacer()
                
                if navigationMode == .viewing {
                    // Button to start navigation
                    Button(action: {
                        // Toggle navigation mode
                        navigationMode = .navigating
                    }) {
                        Text("Start Navigation")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            
            VStack {
                HStack {
                    VStack {
                        let size = overlaySize[navigationMode]!
                        LocalizeOverlay()
                            .frame(width: size.width, height: size.height)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding()
                        Spacer()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarTitle("", displayMode: .inline) // Option
        .onAppear(perform: navigateToRoom)
        .onChange(of: localizerSession.pose, perform: updatePath)
    }
    
    func updatePath(pose: Pose?) {
        guard let pose = pose else { return }
        navigationSession.update(startPoint: pose.pos)
    }
    
    func navigateToRoom() {
        if let pose = localizerSession.pose {
            navigationSession.navigate(startPoint: pose.pos, room: room)
        } else {
            navigationSession.navigate(startPoint: Point3(), room: room)
            localizerSession.localize(on_success: { pose in
                navigationSession.navigate(startPoint: pose.pos, room: room)
            })
        }
    }
}







