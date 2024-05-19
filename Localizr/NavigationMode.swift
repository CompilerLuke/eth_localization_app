//
//  NavigationMode.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 18/05/24.
//

import Foundation
import SwiftUI


import simd



struct NavigationMode: View {
    var room: String
    var theme: MapTheme = MapTheme()
    var floor: Floor?
    var path: [Point2] = []
    var world_to_image: Mat3 = Mat3(diagonal: Point3(1, 1, 1))
    
    var body: some View {
        VStack {
            
            
            // Card to render the map
            VStack {
                
                  
                MapOverlay(room: room)
                                
                    .frame(height: 600)
                   
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
            .padding(10.0)
            
            Spacer()
            
            // Button to start navigation
            Button(action: {
                // Action to start navigation
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
        
      
        .navigationBarTitle("", displayMode: .inline) //1. option
        
    }
}

struct NavigationMode_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMode(room: "HG F 1")
    }
}

