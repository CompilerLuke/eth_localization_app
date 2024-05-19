//
//  HomePage.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 18/05/24.
//

import Foundation
import SwiftUI
import SwiftUI

struct HomePage: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to HG, looking for?")
                .font(.largeTitle)
                .padding(.top, 50)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
            
            CustomButtonView(imageName: "magnifyingglass.circle", text: "A specific room", destination: AnyView(RoomSearchPage()),backgroundColor: Color.white, iconColor: Color.blue)
            
            CustomButtonView(imageName: "building.2", text: "Attractions in the building", destination: AnyView(Text("Attractions Page")), backgroundColor: Color.white, iconColor: Color.blue)
            
            
            
            CustomButtonView(imageName: "graduationcap", text: "Classes of today", destination: AnyView(LessonsView()), backgroundColor: Color.white, iconColor: Color.blue)
            
            CustomButtonView(imageName: "location.circle", text: "My location", destination: AnyView(Text("Location Page")), backgroundColor: Color.blue, iconColor: Color.white)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Home")
    }
}

struct HomePage_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}


