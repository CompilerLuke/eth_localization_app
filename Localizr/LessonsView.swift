//
//  LessonsView.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 18/05/24.
//

import Foundation
import SwiftUI

struct LessonsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Live now")
                .font(.largeTitle)
                .padding(.top, 10)
            
            HStack(spacing: 20) {
                LiveCardView(title: "Informatics", room: "HG F 1")
                LiveCardView(title: "Informatics", room: "HG F 1")
                
            }
            HStack(spacing: 20) {
                LiveCardView(title: "Informatics", room: "HG F 1")
                LiveCardView(title: "Informatics", room: "HG F 1")
                
            }
            
            Text("Starting soon")
                .font(.largeTitle)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                SoonCardView(title: "Informatics", room: "HG F 1")
                SoonCardView(title: "Informatics", room: "HG F 1")
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("", displayMode: .inline) 
    }
        
}

struct LiveCardView: View {
    var title: String
    var room: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(room)
                .font(.subheadline)
            Button(action: {
                // Action for go to button
            }) {
                Text("Go To")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        
    }
        
}

struct SoonCardView: View {
    var title: String
    var room: String
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.headline)
            Text(room)
                .font(.subheadline)
            Button(action: {
                // Action for go to button
            }) 
            {
                Text("Go To")
                    .foregroundColor(Color.blue)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.all, 22.0)
        }
        .padding()
        .frame(height: 70.0)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        
        
    }
        
        
}

struct LessonsView_Previews: PreviewProvider {
    static var previews: some View {
        LessonsView()
    }
}
