//
//  LikedPlacesView.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 8/1/21.
//
import Foundation
import SwiftUI

class LikedList: ObservableObject {
    
    @Published var data: [Place] = [Place]()
    
    init(data: [Place]) {
        self.data = data
    }
    
    func deleteById(placeId: String) {
        self.data = data.filter { place in
            return place.place_id != placeId
        }
    }
}

struct LikedPlacesView: View {
    
    @ObservedObject var places: LikedList
    
    var sendRemoveAction: (Place) -> Void
        
    @State var showRemoveDialog = false
    
    @State var lastClickedPlace: Place? = nil
        
    @Environment(\.colorScheme) var colorScheme
    
    init(places: [Place], sendRemoveAction: @escaping (Place) -> Void) {
        self.places = LikedList(data: places)
        self.sendRemoveAction = sendRemoveAction
    }
    
    var body: some View {
        VStack {
            
            Text("Liked Places")
                .font(.title2)
                .padding(.vertical, 10)
            
            ScrollView(.vertical) {
                //VStack(spacing: 10) {
                //https://stackoverflow.com/questions/60009646/mysterious-spacing-or-padding-in-elements-in-a-vstack-in-a-scrollview-in-swiftui
                VStack(spacing: 0) {
                    ForEach(self.places.data, id: \.self) { place in
                        HStack {
                            // place info
                            HStack {
                                Link(
                                    // todo use name in query instead of Google value
                                    // todo move to common class
                                    destination: URL(string: "https://www.google.com/maps/search/?api=1&query=Google&query_place_id=" + place.place_id!)!,
                                    label: {
                                        Text(place.name!).underline()
                                     })
                                Spacer()
                            
                                let distance = location.distanceFrom(place: place)
                                Text("\(distance)m")
                            }
                            
                            Spacer()
                            
                            // remove liked place button
                            Button(action: {
                                lastClickedPlace = place
                                showRemoveDialog.toggle()
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                            }.alert(isPresented: $showRemoveDialog) {
                                Alert(
                                    title: Text("Do you want to remove this place from liked?"),
                                    message: Text("You can like it again when you see it"),
                                    primaryButton: .destructive(Text("Remove")) {
                                        self.places.deleteById(placeId: self.lastClickedPlace?.place_id ?? "")
                                        if (self.lastClickedPlace != nil) {
                                            self.sendRemoveAction(self.lastClickedPlace!)
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }.padding(.horizontal, 10)
                        }.padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        
                        Divider().padding(.horizontal, 10)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct LikedPlacesView_Previews: PreviewProvider {
    
    static var previews: some View {
        let testPlaces = [
            Place(place_id: "1", name: "Perfect Pizza", rating: 5.0, vicinity: "Rome", geometry: nil, isLiked: true, distance: nil),
            Place(place_id: "2", name: "Crispy Coffee", rating: 5.0, vicinity: "Paris", geometry: nil, isLiked: true, distance: nil)
        ]
        ForEach(ColorScheme.allCases, id: \.self) {
            LikedPlacesView(
                places: testPlaces,
                sendRemoveAction: {
                    (place: Place) -> ()  in
                    print(place)
                }
            ).preferredColorScheme($0)
        }
    }
}


