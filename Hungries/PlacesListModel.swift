//
//  PlacesListModel.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/14/21.
//

import SwiftUI
import Foundation
import CoreLocation

class PlacesListModel: ObservableObject {
    
    let apiUserName = Bundle.main.infoDictionary!["HUNGRIES_API_USERNAME"] as! String
    
    let apiPassword = Bundle.main.infoDictionary!["HUNGRIES_API_PASSWORD"] as! String
    
    @Published var places = [Place]()
    
    @Published var hasNextPage = false
    
    @Published var isLoaded = false
    
    @ObservedObject var auth = authState
    
    // default value before it's changed in settings
    @AppStorage(SETTINGS_KEY_SEARCH_RADIUS) var searchRadius: Int = 500
    
    var loc = location
    
    var nextPageToken: String?
    
    private var fetchedFirstBatch = false;
    
    public func getCurrentPlace() -> Place? {
        if (!fetchedFirstBatch) {
            fetchPlaces(
                nextPageToken: nil,
                lat: loc.selectedLocation!.coordinate.latitude,
                lng: loc.selectedLocation!.coordinate.longitude
            )
            fetchedFirstBatch = true
        }
        return places.first
    }
    
    init() {
        //fetchPlaces(nextPageToken: nil)
    }
    
    public func nextPlace() {
        places.removeFirst()
        if (places.isEmpty && !(nextPageToken ?? "").isEmpty) {
            fetchPlaces(nextPageToken: self.nextPageToken,
                        lat: loc.selectedLocation!.coordinate.latitude,
                        lng: loc.selectedLocation!.coordinate.longitude)
        }
    }
    
    public func fetchPlacesForNewLocation(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        places.removeAll()
        fetchPlaces(nextPageToken: nil, lat: lat, lng: lng)
    }
    
    public func fetchPlaces(nextPageToken: String?, lat: CLLocationDegrees, lng: CLLocationDegrees) {
        self.isLoaded = false
        
        getPlaces(nextPageToken: nextPageToken, lat: lat, lng: lng) { response in
            DispatchQueue.main.async {
                if let response = response {
                    self.nextPageToken = response.nextPageToken
                    self.hasNextPage = response.nextPageToken?.count ?? 0 > 0
                    
                    // for unauthorized users: check local storage and update likes from it
                    let localLikedPlaces = self.auth.isLoggedIn() ? [Place]() : self.getPlacesFromUserDefaults(key: "likedPlaces")
                    let localDislikedPlaces = self.auth.isLoggedIn() ? [Place]() : self.getPlacesFromUserDefaults(key: "dislikedPlaces")
                    
                    response.places?.forEach { p in
                        if (!self.auth.isLoggedIn()) {
                            // find if liked or disliked in local storages
                            let localPlaceLiked = localLikedPlaces.first(where: { $0.id == p.id})
                            let localPlaceDisliked = localDislikedPlaces.first(where: { $0.id == p.id})
                            let ratedBefore = localPlaceLiked != nil || localPlaceDisliked != nil
                            if (ratedBefore) {
                                let localPlace = localPlaceLiked != nil ? localPlaceLiked : localPlaceDisliked
                                let updatedPlace = Place(origin: p, _isLiked: localPlace?.isLiked)
                                self.places.append(updatedPlace)
                            } else {
                                self.places.append(p)
                            }
                        } else {
                            self.places.append(p)
                        }
                    }
                }
                self.isLoaded = true
            }
        }
    }
    
    // todo: common parts in one place, async call, error handle
    public func ratePlace(place: Place, rate: Bool) {
        let placeId = place.id
        if (!auth.isLoggedIn()) {
            saveRatingInUserDefaults(place: place, rate: rate)
            return
        }
        let fireBaseUserID = auth.firebaseUser!.uid 
        let urlString = "https://hungries-api.herokuapp.com/place/\(placeId!)/like/\(fireBaseUserID)/\(rate.description)"
        let urlComps = URLComponents(string: urlString)!
        guard let url = URL(string: urlComps.url!.absoluteString) else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        
        let toEncode = "\(apiUserName):\(apiPassword)"
        let encoded = toEncode.data(using: .utf8)?.base64EncodedString()
        request.addValue("Basic \(encoded!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard data != nil else {
                return
            }
            do {
            } catch {
                print(error)
            }
        }).resume()
    }
    
    
    private func getPlaces(nextPageToken: String?,
                           lat: CLLocationDegrees, lng: CLLocationDegrees,
                           _ completion: @escaping (PlacesResponse?) -> ()) {
        var urlComps = URLComponents(string: "https://hungries-api.herokuapp.com/places")!
        let fireBaseUserID = (auth.firebaseUser != nil) ? auth.firebaseUser!.uid : ""
        urlComps.queryItems = [URLQueryItem(name: "radius", value: String(searchRadius)),
                               URLQueryItem(name: "device", value: fireBaseUserID),
                               URLQueryItem(name: "coordinates", value: String(lat) + "," + String(lng)),]
        if (nextPageToken != nil) {
            urlComps.queryItems?.append(URLQueryItem(name: "pagetoken", value: nextPageToken!))
        }
        
        guard let url = URL(string: urlComps.url!.absoluteString) else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        let toEncode = "\(apiUserName):\(apiPassword)"
        let encoded = toEncode.data(using: .utf8)?.base64EncodedString()
        request.addValue("Basic \(encoded!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard let data = data else {
                return
            }
            do {
                let jsonDecoder = JSONDecoder()
                let placesResp = try jsonDecoder.decode(PlacesResponse.self, from: data)
                completion(placesResp)
            } catch {
                print(error)
                completion(nil)
            }
        }).resume()
    }
    
    // todo move to separate class for defaults storage
    private func saveRatingInUserDefaults(place: Place, rate: Bool) {
        var currentLikedPlaces = getPlacesFromUserDefaults(key: "likedPlaces")
        var currentDislikedPlaces = getPlacesFromUserDefaults(key: "dislikedPlaces")
        
        let placeId = place.id!
        let updatedPlace = Place(origin: place, _isLiked: rate)
        
        // update list: remove or add new
        if (!rate) {
            // check if exist in liked and remove, add to disliked
            currentLikedPlaces = currentLikedPlaces.filter { $0.id != placeId }
            if (!currentDislikedPlaces.contains { $0.id == placeId }) {
                currentDislikedPlaces.append(updatedPlace)
            }
        } else {
            // remove from disliked
            currentDislikedPlaces = currentDislikedPlaces.filter { $0.id != placeId }
            if (!currentLikedPlaces.contains { $0.id == placeId }) {
                currentLikedPlaces.append(updatedPlace)
            }
        }
        
        // save
        do {
            let encoder = JSONEncoder()
            
            let likedPlacesJson = try encoder.encode(currentLikedPlaces)
            UserDefaults.standard.set(likedPlacesJson, forKey: "likedPlaces")
            
            let dislikedPlacesJson = try encoder.encode(currentLikedPlaces)
            UserDefaults.standard.set(dislikedPlacesJson, forKey: "dislikedPlaces")
        } catch {
            print("Unable to Encode Array of Places (\(error))")
        }
    }
    
    private func getPlacesFromUserDefaults(key: String) -> [Place] {
        var currentPlaces = [Place]()
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                currentPlaces = try decoder.decode([Place].self, from: data)
            } catch {
                print("Unable to Decode Places (\(error))")
            }
        }
        return currentPlaces;
    }
}
