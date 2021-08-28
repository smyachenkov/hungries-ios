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
                    response.places?.forEach { p in
                        self.places.append(p)
                    }
                }
                self.isLoaded = true
            }
        }
    }
    
    // todo: common parts in one place, async call, error handle
    public func ratePlace(placeId: Int, place: Place?, rate: Bool) {
        if (!auth.isLoggedIn()) {
            saveRatingInUserDefaults(placeId: placeId, place: place, rate: rate)
            return
        }
        let fireBaseUserID = auth.firebaseUser!.uid 
        let urlString = "https://hungries-api.herokuapp.com/place/\(placeId)/like/\(fireBaseUserID)/\(rate.description)"
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
        urlComps.queryItems = [URLQueryItem(name: "radius", value: "500"),
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
    
    private func saveRatingInUserDefaults(placeId: Int, place: Place?, rate: Bool) {
        // get current data
        var currentPlaces = [Place]()
        if let data = UserDefaults.standard.data(forKey: "likedPlaces") {
            do {
                let decoder = JSONDecoder()
                currentPlaces = try decoder.decode([Place].self, from: data)
            } catch {
                print("Unable to Decode Places (\(error))")
            }
        }
        
        // update list: remove or add new
        if (!rate) {
            // check if exist and remove
            currentPlaces = currentPlaces.filter { $0.id != placeId }
        } else {
            if (place != nil) {
                currentPlaces.append(place!)
            }
        }
        
        // save
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(currentPlaces)
            UserDefaults.standard.set(data, forKey: "likedPlaces")
        } catch {
            print("Unable to Encode Array of Places (\(error))")
        }
        
    }
}
