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




enum NavigationModeState {
    case viewing
    case navigating
}

struct NavigationMode: View {
    var room: String
    var theme: MapTheme = MapTheme()
    var floor: Floor?
    var path: [Point2] = []
    var world_to_image: Mat3 = Mat3(diagonal: Point3(1, 1, 1))
    
    @State private var navigationMode: NavigationModeState = .viewing
    
    var body: some View {
        ZStack {
            if navigationMode == .viewing {
                VStack {
                    // Card to render the map
                    VStack {
                        MapOverlay(room: room, mode: navigationMode)
                            .frame(height: 600)
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(10.0)
                    
                    Spacer()
                    
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
                
                VStack {
                    HStack {
                        VStack {
                            LocalizeOverlay()
                                .frame(width: 100, height: 100)
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
            } else if navigationMode == .navigating {
                
                VStack {
                    HStack{
                        // Card to render the map
                        VStack {
                            LocalizeOverlay()
                                .frame(width:300, height:500)
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                                .padding()
                            
                        }
                        Spacer()
                    }
                    
                    
                    Spacer()
                    
                    // Button to start navigation
                    Button(action: {
                        // Toggle navigation mode
                        navigationMode = .viewing
                    }) {
                        Text("Stop Navigation")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                
                VStack {
                    
                    Spacer()
                    HStack {
                       
                        Spacer()
                    VStack {
                        
                            MapOverlay(room: room, mode: navigationMode)
                            .frame(width: 200, height: 200)
                        }
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(10.0)
                        .padding (.bottom, 100)
                        
                                                
                    }
                    
                }
                

                
            }
        }
        .navigationBarTitle("", displayMode: .inline) // Option
    }
}







