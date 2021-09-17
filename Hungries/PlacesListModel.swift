//
//  PlacesListModel.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/14/21.
//

import SwiftUI
import Foundation
import CoreLocation
import Firebase
import GooglePlaces
import GoogleMaps

class PlacesListModel: ObservableObject {
    
    let apiUserName = Bundle.main.infoDictionary!["HUNGRIES_API_USERNAME"] as! String
    
    let apiPassword = Bundle.main.infoDictionary!["HUNGRIES_API_PASSWORD"] as! String
    
    @Published var places = [LocalizedPlace]()
    
    @Published var hasNextPage = false
    
    @Published var isLoaded = false
    
    @ObservedObject var auth = authState
    
    // default value before it's changed in settings
    @AppStorage(SETTINGS_KEY_SEARCH_RADIUS) var searchRadius: Int = 500
        
    var nextPageToken: String?
    
    private var fetchedFirstBatch = false;
    
    private var firebaseRdRef = Database.database().reference()
    
    public func getCurrentPlace() -> LocalizedPlace? {
        if (!fetchedFirstBatch) {
            fetchPlaces(
                nextPageToken: nil,
                lat: location.selectedLocation!.coordinate.latitude,
                lng: location.selectedLocation!.coordinate.longitude
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
                        lat: location.selectedLocation!.coordinate.latitude,
                        lng: location.selectedLocation!.coordinate.longitude)
        }
    }
    
    public func fetchPlacesForNewLocation() {
        places.removeAll()
        let lat = location.selectedLocation!.coordinate.latitude
        let lng = location.selectedLocation!.coordinate.longitude
        fetchPlaces(nextPageToken: nil, lat: lat, lng: lng)
    }
    
    // todo convert place to new place struct with distance and likes
    public func fetchPlaces(nextPageToken: String?, lat: CLLocationDegrees, lng: CLLocationDegrees) {
        self.isLoaded = false
        getPlaces(nextPageToken: nextPageToken, lat: lat, lng: lng) { response in
            DispatchQueue.main.async {
                if let response = response {
                    self.nextPageToken = response.next_page_token
                    self.hasNextPage = response.next_page_token?.count ?? 0 > 0
                    
                    // for unauthorized users: check local storage and update likes from it
                    let localLikedPlaces = self.auth.isLoggedIn() ? [Place]() : self.getPlacesFromUserDefaults(key: "likedPlaces")
                    let localDislikedPlaces = self.auth.isLoggedIn() ? [Place]() : self.getPlacesFromUserDefaults(key: "dislikedPlaces")
                    
                    response.results?.forEach { p in
                        let distanceTo = location.distanceFrom(place: p)

                        // todo calculate distance
                        if (!self.auth.isLoggedIn()) {
                            let localPlaceLiked = localLikedPlaces.first(where: { $0.place_id == p.place_id})
                            let localPlaceDisliked = localDislikedPlaces.first(where: { $0.place_id == p.place_id})
                            let ratedBefore = localPlaceLiked != nil || localPlaceDisliked != nil
                            if (ratedBefore) {
                                self.places.append(
                                    LocalizedPlace(
                                        place: (localPlaceLiked != nil ? localPlaceLiked : localPlaceDisliked)!,
                                        isLiked: localPlaceLiked != nil,
                                        distance: distanceTo
                                    )
                                )
                            } else {
                                self.places.append(
                                    LocalizedPlace(place: p, isLiked: nil, distance: distanceTo)
                                )
                            }
                        } else {
                            let fireBaseUserID = self.auth.firebaseUser!.uid
                            
                            self.firebaseRdRef
                                .child("users/\(fireBaseUserID)/ratings/liked/\(p.place_id!)/")
                                .getData(completion: { (error, snapshot) in
                                    if (snapshot.exists()) {
                                        log.info("Found saved liked rating for place", context: p.place_id)
                                        self.places.append(LocalizedPlace(place: p, isLiked: true, distance: distanceTo))
                                    } else {
                                        self.firebaseRdRef
                                            .child("users/\(fireBaseUserID)/ratings/disliked/\(p.place_id!)/")
                                            .getData(completion: { (error, snapshot) in
                                                if (snapshot.exists()) {
                                                    log.info("Found saved disliked rating for place", context: p.place_id)
                                                    self.places.append(LocalizedPlace(place: p, isLiked: false, distance: distanceTo))
                                                } else {
                                                    log.info("No saved rating for place", context: p.place_id)
                                                    self.places.append(LocalizedPlace(place: p, isLiked: nil, distance: distanceTo))
                                                }
                                            })
                                    }
                                })
                        }
                    }
                }
                self.isLoaded = true
            }
        }
    }
    
    public func ratePlace(place: Place, rate: Bool) {
        if (!auth.isLoggedIn()) {
            saveRatingInUserDefaults(place: place, rate: rate)
        } else {
            let fireBaseUserID = auth.firebaseUser!.uid
            
            // save place if not exist
            firebaseRdRef.child("places/\(place.place_id!)/").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    // todo update if was not updated for long time
                    log.info("Place already exist in fb storate", context: place.place_id)
                } else {
                    log.info("Saving new place to fb storage", context: place)
                    let savedPlaceDict = place.asDictionary()
                    self.firebaseRdRef.child("places/\(place.place_id!)/").setValue(savedPlaceDict)
                }
            })
            
            // remove if exist in opposite rating collection
            firebaseRdRef
                .child("users/\(fireBaseUserID)/ratings/\(rate ? "disliked" : "liked")/\(place.place_id!)")
                .removeValue()
            
            // save rating
            firebaseRdRef
                .child("users/\(fireBaseUserID)/ratings/\(rate ? "liked" : "disliked")/\(place.place_id!)")
                .setValue(["date": Date().currentTimeMillis()])
        }
    }
    
    
    
    private func getPlaces(nextPageToken: String?,
                           lat: CLLocationDegrees, lng: CLLocationDegrees,
                           _ completion: @escaping (PlacesResponse?) -> ()) {
        var urlComps = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
        
        urlComps.queryItems = [URLQueryItem(name: "radius", value: String(searchRadius)),
                               URLQueryItem(name: "location", value: String(lat) + "," + String(lng)),
                               URLQueryItem(name: "type", value: "restaurant"),
                               URLQueryItem(name: "key", value: Bundle.main.infoDictionary!["GMS_SERVICES_API_KEY"] as? String),]
        
        if (nextPageToken != nil) {
            urlComps.queryItems?.append(URLQueryItem(name: "pagetoken", value: nextPageToken!))
        }
        
        guard let url = URL(string: urlComps.url!.absoluteString) else {
            log.error("Invalid URL")
            return
        }
                
        var request = URLRequest(url: url)
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
                log.error("error parsing nearby search response", context: error)
                completion(nil)
            }
        }).resume()
    }
    
    // todo move to separate class for defaults storage
    private func saveRatingInUserDefaults(place: Place, rate: Bool) {
        var currentLikedPlaces = getPlacesFromUserDefaults(key: "likedPlaces")
        var currentDislikedPlaces = getPlacesFromUserDefaults(key: "dislikedPlaces")
        
        let placeId = place.place_id!
        let updatedPlace = Place(origin: place, _isLiked: rate)
        
        // update list: remove or add new
        if (!rate) {
            // check if exist in liked and remove, add to disliked
            currentLikedPlaces = currentLikedPlaces.filter { $0.place_id != placeId }
            if (!currentDislikedPlaces.contains { $0.place_id == placeId }) {
                currentDislikedPlaces.append(updatedPlace)
            }
        } else {
            // remove from disliked
            currentDislikedPlaces = currentDislikedPlaces.filter { $0.place_id != placeId }
            if (!currentLikedPlaces.contains { $0.place_id == placeId }) {
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
            log.error("Unable to Encode Array of Places",  context: error)
        }
    }
    
    private func getPlacesFromUserDefaults(key: String) -> [Place] {
        var currentPlaces = [Place]()
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                currentPlaces = try decoder.decode([Place].self, from: data)
            } catch {
                log.error("Unable to Decode places from defaults", context: error)
            }
        }
        return currentPlaces;
    }
}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
