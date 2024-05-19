//
//  CustomButton.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 18/05/24.
//

import Foundation
import SwiftUI

import SwiftUI

import SwiftUI

struct CustomButtonView: View {
    var imageName: String
    var text: String
    var destination: AnyView
    var backgroundColor: Color
    var iconColor: Color

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(iconColor) // Set icon color
                    .padding()

                Text(text)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(backgroundColor) // Set background color
            .cornerRadius(15)
            .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
}

struct CustomButtonView_Previews: PreviewProvider {
    static var previews: some View {
        CustomButtonView(imageName: "building.2", text: "A specific room", destination: AnyView(Text("Room Search Page")), backgroundColor: Color.blue, iconColor: Color.white)
    }
}
