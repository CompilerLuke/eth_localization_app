//
//  RoomSearch.swift
//  localizr
//
//  Created by Camilla Mazzoleni on 18/05/24.
//

import Foundation
import SwiftUI
import simd

struct RoomSearchPage: View {
    @State private var searchText = ""
    @State private var selectedFloor: String? = nil
    @State private var showFilterSheet = false
    @State private var rooms: [Room] = []
    
    var floors: [String] {
        Array(Set(rooms.map { String($0.label.prefix(1)) })).sorted()
    }
    
    var filteredRooms: [Room] {
        rooms.filter { room in
            (searchText.isEmpty || room.label.localizedCaseInsensitiveContains(searchText)) &&
            (selectedFloor == nil || room.label.hasPrefix(selectedFloor!))
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search rooms...", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button(action: {
                    showFilterSheet = true
                }) {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .imageScale(.large)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            
            
                    List(filteredRooms) { room in
                        NavigationLink(destination: NavigationMode(room: room.label)) {
                            Text(room.label)
                                .padding()
                    }
                        .listStyle(PlainListStyle())
                    
            }
        }
        .actionSheet(isPresented: $showFilterSheet) {
            ActionSheet(title: Text("Filter by Floor"), buttons: filterButtons)
        }
        .onAppear {
            loadRooms()
        }
        .navigationBarTitle("Search rooms", displayMode: .inline) //1. option
    }
    
    var filterButtons: [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = floors.map { floor in
            .default(Text(floor)) {
                selectedFloor = floor
            }
        }
        buttons.append(.cancel {
            selectedFloor = nil
        })
        return buttons
    }
    
    func loadRooms() {
        // Load and parse the JSON file
        if let url = Bundle.main.url(forResource: "building", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let building = try? JSONDecoder().decode(Building.self, from: data) {
            // Extract rooms
            rooms = building.floors.flatMap { $0.locations }
        } else {
            print("Failed to load or parse the JSON file.")
        }
    }
}


