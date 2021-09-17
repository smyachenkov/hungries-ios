//
//  ChooseLocationView.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 9/17/21.
//

import Foundation

import Foundation
import SwiftUI
import CoreLocation
import GoogleMaps

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

struct ChooseLocationView: View {
    
    private var mapView: GMSMapView
    private var onNewLocation: () -> Void
    private var onCancel: () -> Void
    
    init(onNewLocation: @escaping () -> Void,
         onCancel: @escaping () -> Void) {
        self.mapView = GMSMapView.map(
            withFrame: CGRect.zero,
            camera: GMSCameraPosition.camera(
                withLatitude: location.lastLocation!.coordinate.latitude,
                longitude: location.lastLocation!.coordinate.longitude,
                zoom: 15.0
            )
        )
        self.onNewLocation = onNewLocation
        self.onCancel = onCancel
    }
    
    var body: some View {
        
        ZStack {
            GoogleMapsView(mapView: mapView)
            
            Image(systemName: "mappin")
                .foregroundColor(.red)
                .font(.system(size: 32))
            
        }
        HStack {
            
            HStack {
                Button(action: {
                    self.onCancel()
                }) {
                    Image(systemName: "arrowshape.turn.up.backward.fill")
                }.padding(.leading, 20)
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    // update location
                    let selectedLat = mapView.projection.coordinate(for: mapView.center).latitude
                    let selectedLng = mapView.projection.coordinate(for: mapView.center).longitude
                    location.selectNewLocation(newLocation: CLLocation.init(latitude: selectedLat, longitude: selectedLng))
                    
                    // fetch new places
                    self.onNewLocation()
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
