//
//  HomePage.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 26/05/24.
//

import Foundation
import SwiftUI
struct HomePage: View {
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Text("Welcome to HG!")
                .font(.title3)
                .padding(.top, 50)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("Looking for?")
                .font(.largeTitle)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .center)
            
            
            CustomButtonView(imageName: "magnifyingglass.circle", text: "A specific room", destination: AnyView(RoomSearchPage()),backgroundColor: Color.blue.opacity(0.05), iconColor: Color.blue)
            
            
            
            CustomButtonView(imageName: "graduationcap", text: "Classes of today", destination: AnyView(LessonsPage()), backgroundColor: Color.blue.opacity(0.05), iconColor: Color.blue)
            
            CustomButtonView(imageName: "location.circle", text: "My location", destination: AnyView(LocalizationPage()), backgroundColor: Color.blue, iconColor: Color.white)
            
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
