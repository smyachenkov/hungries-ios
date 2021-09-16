//
//  Place.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/12/21.
//

import Foundation


// place with data for current session and user
struct LocalizedPlace: Hashable {
    let place: Place
    let isLiked: Bool?
    let distance: Int?
}


// Google Places API response models
struct PlacesResponse : Codable {
    let results: [Place]?
    let next_page_token: String?
}

struct Place: Codable, Hashable {
    let place_id: String?
    let name: String?
    let rating: Double?
    let vicinity: String?
    let geometry: GeometryModel?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(place_id)
    }
}

struct GeometryModel: Codable, Hashable {
    let location: LocationModel?
}

struct LocationModel: Codable, Hashable {
    let lat: Double?
    let lng: Double?
}

struct OpeningHoursModel: Codable {
    let open_now: Bool?
}

struct PhotoModel: Codable, Hashable {
    let photo_reference: String?
}

extension Place {
    init(origin: Place, _isLiked: Bool?) {
        place_id = origin.place_id
        name = origin.name
        rating = origin.rating
        vicinity = origin.vicinity
        geometry = origin.geometry
    }
    
    func asDictionary() -> [String : Any] {
        return [
            "place_id" : self.place_id!,
            "name" : self.name!,
            "rating": self.rating ?? 0.0,
            "vicinity": self.vicinity ?? "",
            "geometry": [
                "location": [
                    "lat": self.geometry?.location?.lat,
                    "lng": self.geometry?.location?.lng
                ]
            ]
        ] as [String : Any]
    }
}

