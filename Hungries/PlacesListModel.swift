//
//  PlacesListModel.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/14/21.
//

import Foundation
import CoreLocation

class PlacesListModel: ObservableObject {
    
    
    let apiUserName = Bundle.main.infoDictionary!["HUNGRIES_API_USERNAME"] as! String
    
    let apiPassword = Bundle.main.infoDictionary!["HUNGRIES_API_PASSWORD"] as! String
    
    @Published var places = [Place]()
    
    @Published var hasNextPage = false
    
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
        getPlaces(nextPageToken: nextPageToken, lat: lat, lng: lng) { response in
            DispatchQueue.main.async {
                if let response = response {
                    self.nextPageToken = response.nextPageToken
                    self.hasNextPage = response.nextPageToken?.count ?? 0 > 0
                    response.places?.forEach { p in
                        self.places.append(p)
                    }
                }
            }
        }
    }
    
    private func getPlaces(nextPageToken: String?,
                           lat: CLLocationDegrees, lng: CLLocationDegrees,
                           _ completion: @escaping (PlacesResponse?) -> ()) {
        var urlComps = URLComponents(string: "https://hungries-api.herokuapp.com/places")!
        urlComps.queryItems = [URLQueryItem(name: "radius", value: "500"),
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
}
