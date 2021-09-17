//
//  ContentView.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/11/21.
//

import SwiftUI
import CoreLocation
import GoogleMaps
import GooglePlaces

struct ContentView: View {
    
    @ObservedObject var placesListModel = PlacesListModel()
    
    @ObservedObject var likedPlacesListModel = LikedPlacesListModel()
    
    @ObservedObject var loc = location
    
    @ObservedObject var auth = authState
    
    @State private var showMapsPicker = false
    
    @State private var showUserSettigns = false
    
    @State private var showLikedList = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if !auth.authChecked {
            AuthScreenView()
        } else {
            HStack {
                // saved
                Button(action: {
                    self.showLikedList.toggle()
                    self.likedPlacesListModel.fetchLikedPlaces()
                }) {
                    Image(systemName: "list.bullet")
                        .padding(3)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }.font(.title)
                .frame(maxWidth: .infinity)
                .sheet(isPresented: $showLikedList) {
                    if (self.likedPlacesListModel.isLoaded) {
                        LikedPlacesView(
                            places: self.likedPlacesListModel.places,
                            sendRemoveAction: {
                                (place: Place) -> ()  in
                                self.placesListModel.ratePlace(place: place, rate: false)
                            }
                        )
                    }
                }
                
                // settings
                Button(action: {
                    self.showUserSettigns.toggle()
                }) {
                    Image(systemName: "gear")
                        .padding(3)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }.font(.title)
                .frame(maxWidth: .infinity)
                .sheet(isPresented: $showUserSettigns) {
                    UserSettingsView()
                }
            }
            
            VStack {
                if (loc.selectedLocation != nil) {
                    let localizedPlace = placesListModel.getCurrentPlace()
                    if !placesListModel.isLoaded {
                        LoadingCardView()
                    } else if placesListModel.places.count == 0 && !placesListModel.hasNextPage {
                        LastCardView(
                            reloadAction: {
                                self.placesListModel.fetchPlacesForNewLocation()
                            }
                        )
                    } else if localizedPlace != nil {
                        CardView(
                            localizedPlace: localizedPlace!,
                            onSwipe: {
                                (liked: Bool) -> ()  in
                                let place = placesListModel.getCurrentPlace()!
                                self.placesListModel.ratePlace(place: place.place, rate: liked)
                                self.placesListModel.nextPlace()
                            }
                        )
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    let place = placesListModel.getCurrentPlace()!
                    self.placesListModel.ratePlace(place: place.place, rate: false)
                    self.placesListModel.nextPlace()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }.font(.title)
                .frame(maxWidth: .infinity)
                .isHidden(placesListModel.places.isEmpty)
                
                // change location
                Button(action: {
                    self.showMapsPicker.toggle()
                }) {
                    Image(systemName: "map")
                }.font(.title)
                .frame(maxWidth: .infinity)
                .sheet(isPresented: $showMapsPicker,
                       onDismiss: {
                            self.showMapsPicker = false
                       }) {
                    if (loc.lastLocation != nil) {
                        ChooseLocationView(
                            onNewLocation: {
                                self.placesListModel.fetchPlacesForNewLocation()
                                self.showMapsPicker = false
                            },
                            onCancel: {
                                self.showMapsPicker = false
                            }
                        )
                    }
                }
                
                Button(action: {
                    let localizedPlace = placesListModel.getCurrentPlace()!
                    self.placesListModel.ratePlace(place: localizedPlace.place, rate: true)
                    self.placesListModel.nextPlace()
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }.font(.title)
                .frame(maxWidth: .infinity)
                .isHidden(placesListModel.places.isEmpty)
            }
        }
    }
}

extension View {
    
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
