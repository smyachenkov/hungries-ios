//
//  LikedPlacesListModel.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 6/14/21.
//

import Foundation
import CoreLocation


class LikedPlacesListModel: ObservableObject {
    
    let apiUserName = Bundle.main.infoDictionary!["HUNGRIES_API_USERNAME"] as! String
    
    let apiPassword = Bundle.main.infoDictionary!["HUNGRIES_API_PASSWORD"] as! String

    @Published var places = [Place]()

    @Published var isLoaded = false
    
    init() {
    }
    
    public func fetchLikedPlaces(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        self.isLoaded = false
        getLikedPlaces(lat: lat, lng: lng) { response in
            DispatchQueue.main.async {
                if let response = response {
                    self.places.removeAll()
                    response.places?.forEach { p in
                        self.places.append(p)
                    }
                    self.isLoaded = true
                }
            }
        }
    }
    
    private func getLikedPlaces(lat: CLLocationDegrees, lng: CLLocationDegrees, _ completion: @escaping (PlacesResponse?) -> ()) {
        var urlComps = URLComponents(string: "https://hungries-api.herokuapp.com/places/liked")!
        urlComps.queryItems = [URLQueryItem(name: "device", value: deviceId),
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
}
