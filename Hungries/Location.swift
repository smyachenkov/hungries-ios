//
//  Location.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/14/21.
//

import Foundation
import CoreLocation


class Location: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    var locationStatus: CLAuthorizationStatus?
    
    // location of device
    @Published var lastDeviceLocation: CLLocation?
    
    // last observed or last selected by user
    @Published var selectedLocation: CLLocation?
    
    @Published var isLoaded = false
    
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.requestLocation()
            self.isLoaded = true
        }
    }
    
    var statusString: String {
        guard let status = locationStatus else {
            return "unknown"
        }
        switch status {
            case .notDetermined: return "notDetermined"
            case .authorizedWhenInUse: return "authorizedWhenInUse"
            case .authorizedAlways: return "authorizedAlways"
            case .restricted: return "restricted"
            case .denied: return "denied"
            default: return "unknown"
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastDeviceLocation = location
        if (selectedLocation == nil) {
            selectedLocation = lastDeviceLocation
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error("Error requesting user's location", context: error.localizedDescription)
    }
    
    func selectNewLocation(newLocation: CLLocation) {
        selectedLocation = newLocation
    }
    
    // todo return string with meters/kilometers
    func distanceFrom(place: Place?) -> Int {
        if (place == nil || place?.geometry == nil || place?.geometry?.location == nil) {
            return -1
        }
        let fromLoc = CLLocation(latitude: place!.geometry!.location!.lat!, longitude: place!.geometry!.location!.lng!)
        return Int(selectedLocation!.distance(from: fromLoc))
    }
}
