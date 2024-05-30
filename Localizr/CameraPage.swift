//
//  CameraPage.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 22/05/24.
//

import SwiftUI
import Combine
import ARKit
import RealityKit

struct CameraPage: View {
    @EnvironmentObject var localizerSession: LocalizerSession
    @State private var isLoading: Bool = false
    @State private var shouldNavigate: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var location: Point3?

    var body: some View {
        VStack {
            Spacer()
            
            LocalizeOverlay()
                .frame(height: 600) // Set height for the card
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()

            Spacer()

            if isLoading {
                ProgressView("Localizing...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Button(action: {
                    // Start localization and set loading state
                    isLoading = true
                    localizerSession.localize()
                }) {
                    Text("Start Localization")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }

            NavigationLink(destination: LocalizationPage(location: location), isActive: $shouldNavigate) {
                EmptyView()
            }
        }
        .onAppear {
            // Observe changes in the localization process to update the loading state and navigate
            
            localizerSession.$pose
                .receive(on: DispatchQueue.main)
                .sink { newPose in
                    if let newPose = newPose {
                        isLoading = false
                        location = newPose.pos
                        shouldNavigate = true // Navigate to the destination page when the localization is done
                    }
                }
                .store(in: &cancellables)
        }
        .navigationBarTitle("Localization", displayMode: .inline)
        
    }
}




