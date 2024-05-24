//
//  NavigationSearch.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import SwiftUI



struct Handle : View {
    @EnvironmentObject var theme : AppTheme
    
    private let handleThickness = CGFloat(5.0)
    var body: some View {
        RoundedRectangle(cornerRadius: handleThickness / 2.0)
            .frame(width: 40, height: handleThickness)
            .foregroundColor(theme.fg)
            .contentShape(Rectangle())
            .padding(5)
    }
}

enum DragState {
    case inactivate
    case dragging(translation: CGSize)
}

func translation(_ dragState: DragState) -> CGSize {
    switch dragState {
    case .inactivate: return CGSize(width:0.0,height:0.0)
    case .dragging(let trans): return trans
    }
}

func isDragging(_ dragState: DragState) -> Bool {
    switch dragState {
    case .inactivate: return false
    case .dragging: return true
    }
}

/*
    var translation : CGSize {
        switch self {
        case .inactivate: return CGSize(width:0.0,height:0.0)
        case .dragging(let trans): return trans
    }
        
    var isDragging: Bool {
        switch self {
        case .inactivate: return false
        case .dragging: return true
        }
    }
}*/


struct SwipeupCard<T: View> : View {
    @EnvironmentObject var theme : AppTheme
    var maxOffset = UIScreen.main.bounds.height * 0.3
    @State var minimized : Bool = true
    @GestureState var dragState : DragState = .inactivate
    var height : CGFloat {
        min(-translation(dragState).height + (minimized ? 0 : maxOffset), maxOffset)
    }
    @ViewBuilder var content: () -> T
    
    var body : some View {
        VStack(alignment: .center, spacing: 10) {
            Handle()
            content()
        }
        .padding(10)
        .frame(minHeight: UIScreen.main.bounds.height * 0.3, alignment: .top)
        .background(theme.card1_bg)
        .offset(y: -height)
        .animation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0), value: translation(dragState).height)
        .gesture(DragGesture()
        .updating($dragState) { value, state, transaction in
            state = .dragging(translation: value.translation)
        }
        .onEnded { value in
            let height = -value.predictedEndTranslation.height
            minimized = abs(height) < abs(height-maxOffset)
            print("Height \(height) \(maxOffset) \(minimized)")
        })
     }
}

struct LocationGridItem : View {
    var name : String
    var icon : String
    var color : Color
    
    var body : some View {
        VStack{
            Text(name).font(Font.system(size: 20))
            Image(systemName: icon).font(Font.system(size: 20))
        }
        .padding(10)
        //.containerRelativeFrame([.horizontal], count: 2, spacing: 1)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 80)
        .background(color)
    }
}

struct LocationGrid : View {
    var body : some View {
        VStack{
            HStack {
                LocationGridItem(
                    name:"Bathroom",
                    icon:"figure.dress.line.vertical.figure",
                    color:Color(red: 0.9, green: 0.5, blue: 0.5)
                )
                LocationGridItem(
                    name:"Restaurant",
                    icon:"fork.knife",
                    color:Color(red: 0.5, green: 0.9, blue: 0.5)
                )
            }
            HStack {
                LocationGridItem(
                    name:"Conference",
                    icon:"person.3",
                    color: Color(red: 0.5, green: 0.9, blue: 1.0)
                )
                LocationGridItem(
                    name:"Computer",
                    icon:"laptopcomputer",
                    color: Color(red: 0.9, green: 0.5, blue: 0.9)
                )
            }
        }.padding(10)
    }
}

struct NavigationSearchView: View {
    @EnvironmentObject var theme : AppTheme
    @State var searchName : String = ""
    @State var minimized : Bool = true
    @State var selected : Location?
    
    var searchResults : [Location]
    var onSearch : (String) -> ()
    var navigateTo : (Location) -> ()
    var canNavigate: Bool
    
    var body : some View {
        if let selected = selected {
            VStack {
                Text("Room")
                Text(selected.label)
                
                if(!canNavigate) {
                    Text("Localize First")
                }
                Button(action: {
                    navigateTo(selected)
                }) {
                    Text("Go")
                }
            }.padding(10)
        } else {
            VStack {
                TextField("", text: $searchName, prompt: Text("Search map"))
                    .onTapGesture {
                        minimized = false
                    }
                    .onChange(of: searchName, perform: { _ in onSearch(searchName) })
                    .padding(5)
                    .foregroundColor(theme.fg)
                    .background(theme.card3_shadow)
                
                if(searchResults.isEmpty) {
                    LocationGrid()
                }
                
                //List{
                    ForEach(searchResults) { item in
                        Button(action: {
                            self.selected = item
                        }) {
                            VStack{
                                HStack{
                                    Image(systemName: "door.left.hand.closed").foregroundColor(theme.fg)
                                    Text("Room \(item.label)").foregroundColor(theme.fg)
                                    Spacer()
                                }
                                Text(item.desc)
                            }
                            .padding(10)
                            //.background(theme.card2_shadow)
                        }
                    }
                //}
            }.padding(10)
        }
    }
}

struct NavigationSearch: View {
    @EnvironmentObject var localizerSession : LocalizerSession
    @EnvironmentObject var navigationSession : NavigationSession
    @EnvironmentObject var buildingService : BuildingService
    @State var searchResults : [Location] = []
    
    func onSearch(name: String) {
        buildingService.queryLocations(name: name, on_success: { results in
            DispatchQueue.main.async { self.searchResults = results }
        }, on_failure: { err in
            
        })
    }
    
    func navigate(location: Location) {
        navigationSession.navigate(dstLocation: location.id)
    }
    
    var body: some View {
        NavigationSearchView(searchResults: searchResults, onSearch: onSearch, navigateTo: navigate, canNavigate: localizerSession.pose?.pos != nil)
    }
}

#Preview {
    VStack{
        Text("Hello World!").foregroundColor(.black)
        
        NavigationSearchView(
            searchName:"15",
            searchResults:
                //[
                //Location(id: 1, label: "15", desc: "hello", contour: [])
            //],
            [],
            onSearch: { value in },
            navigateTo: { location in },
            canNavigate: false
        ).environmentObject(AppTheme())
    }
}
