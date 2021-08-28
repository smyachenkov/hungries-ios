//
//  LikedPlacesListModel.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 6/14/21.
//

import Foundation
import CoreLocation
import SwiftUI


class LikedPlacesListModel: ObservableObject {
    
    let apiUserName = Bundle.main.infoDictionary!["HUNGRIES_API_USERNAME"] as! String
    
    let apiPassword = Bundle.main.infoDictionary!["HUNGRIES_API_PASSWORD"] as! String

    @Published var places = [Place]()

    @Published var isLoaded = false
    
    @ObservedObject var auth = authState
    
    init() {
    }
    
    public func fetchLikedPlaces(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        self.isLoaded = false
        self.places.removeAll()
        if (auth.isLoggedIn()) {
            getLikedPlacesFromApi(lat: lat, lng: lng) { response in
                DispatchQueue.main.async {
                    if let response = response {
                        response.places?.forEach { p in
                            self.places.append(p)
                        }
                        self.isLoaded = true
                    }
                }
            }
        } else {
            self.places = getLikedPlacesFromUserDefaults()
        }
    }
    
    private func getLikedPlacesFromApi(lat: CLLocationDegrees, lng: CLLocationDegrees, _ completion: @escaping (PlacesResponse?) -> ()) {
        guard let fireBaseUserID =  auth.firebaseUser?.uid else { return }
        var urlComps = URLComponents(string: "https://hungries-api.herokuapp.com/places/liked")!
        urlComps.queryItems = [URLQueryItem(name: "device", value: fireBaseUserID),
                               URLQueryItem(name: "coordinates", value: String(lat) + "," + String(lng)),]
        
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
    
    private func getLikedPlacesFromUserDefaults() -> [Place] {
        if let data = UserDefaults.standard.data(forKey: "likedPlaces") {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode([Place].self, from: data)
            } catch {
                print("Unable to Decode Places (\(error))")
            }
        }
        return [Place]()
    }
}
