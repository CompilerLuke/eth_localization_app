//
//  LocalizationPage.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 22/05/24.
//

import SwiftUI
import simd
import Foundation
import Combine

struct LocalizationPage: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var localizerSession: LocalizerSession
    
    @State private var isLoading: Bool = true
    @State private var location: Point3?
    
    var floor: Floor?
    var path: [Point2] = []
    var world_to_image: Mat3 = Mat3(diagonal: Point3(1, 1, 1))

    init( location: Point3? = nil) {
          
            self._location = State(initialValue: location)
            self._isLoading = State(initialValue: location == nil)
        }

    var body: some View {
        ZStack {
            VStack {
                
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(height: 600)
                } else if let location = location {
                    // Card to render the map
                    VStack {
                        MapOverlay(mode: .viewing)
                            .frame(height: 600)
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(10.0)
                }
                
                Spacer()
                
                // Navigation Link to RoomSearchPage
                NavigationLink(destination: RoomSearchPage()) {
                    HStack {
                        Image(systemName: "magnifyingglass.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color.white)

                        Text("Search Room")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            
            // Add the LocalizeOverlay on top
            VStack {
                HStack {
                    
                    VStack {
                        LocalizeOverlay()
                            .frame(width: 150, height: 200) // Set the size of the overlay
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
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            // 1
            ToolbarItem(placement: .navigationBarTrailing) {
                
                Button("Home") {
                    
                    
                }
            }
        }
    
                
        
    }
}








