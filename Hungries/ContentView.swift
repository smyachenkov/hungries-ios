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

struct GoogleMapsView: UIViewRepresentable {
    
    var mapView: GMSMapView
    
    func makeUIView(context: Self.Context) -> GMSMapView {
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.zoomGestures = true
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
    }
    
}

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
                    self.likedPlacesListModel.fetchLikedPlaces(
                        lat: loc.selectedLocation!.coordinate.latitude,
                        lng: loc.selectedLocation!.coordinate.longitude
                    )
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
                    let place = placesListModel.getCurrentPlace()
                    
                    if !placesListModel.isLoaded {
                        LoadingCardView()
                    } else if placesListModel.places.count == 0 && !placesListModel.hasNextPage {
                        LastCardView(
                            reloadAction: {
                                self.placesListModel.fetchPlacesForNewLocation(
                                    lat: loc.selectedLocation!.coordinate.latitude,
                                    lng: loc.selectedLocation!.coordinate.longitude
                                )
                            }
                        )
                    } else if place != nil {
                        CardView(
                            place: place!,
                            onSwipe: {
                                (liked: Bool) -> ()  in
                                let place = placesListModel.getCurrentPlace()!
                                self.placesListModel.ratePlace(place: place, rate: liked)
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
                    self.placesListModel.ratePlace(place: place, rate: false)
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
                .sheet(isPresented: $showMapsPicker) {
                    // todo move all this to different file
                    if (loc.lastLocation != nil) {
                        let mapView = GMSMapView.map(
                            withFrame: CGRect.zero,
                            camera: GMSCameraPosition.camera(
                                withLatitude: loc.lastLocation!.coordinate.latitude,
                                longitude: loc.lastLocation!.coordinate.longitude,
                                zoom: 15.0
                            )
                        )
                        ZStack {
                            
                            GoogleMapsView(mapView: mapView)
                            
                            Image(systemName: "mappin")
                                .foregroundColor(.red)
                                .font(.system(size: 32))
                            
                        }
                        HStack {
                            
                            HStack {
                                Button(action: {
                                    self.showMapsPicker.toggle()
                                }) {
                                    Image(systemName: "arrowshape.turn.up.backward.fill")
                                }.padding(.leading, 20)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button(action: {
                                    let selectedLat = mapView.projection.coordinate(for: mapView.center).latitude
                                    let selectedLng = mapView.projection.coordinate(for: mapView.center).longitude
                                    loc.selectNewLocation(newLocation: CLLocation.init(latitude: selectedLat, longitude: selectedLng))
                                    self.placesListModel.fetchPlacesForNewLocation(lat: selectedLat, lng: selectedLng)
                                    self.showMapsPicker.toggle()
                                }) {
                                    HStack {
                                        Image(systemName: "location")
                                        Text("Use this location")
                                    }.padding(10)
                                }.overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 2.0)
                                ).font( .system(size: 14))
                            }
                            
                            Spacer()
                            
                            // hidden copy of the return button, just to center use location button
                            HStack {
                                Button(action: {
                                }) {
                                    Image(systemName: "arrowshape.turn.up.backward.fill")
                                }.padding(.leading, 20)
                            }.hidden()
            
                        }.padding(3)
                    }
                }
                
                Button(action: {
                    let place = placesListModel.getCurrentPlace()!
                    self.placesListModel.ratePlace(place: place, rate: true)
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
