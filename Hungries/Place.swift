//
//  Place.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/12/21.
//

import Foundation

struct PlacesResponse : Decodable {
    let places: [Place]?
    let nextPageToken: String?
}

struct Place: Decodable, Hashable {
    let id : Int?
    let googlePlaceId : String?
    let name : String?
    let url : String?
    let distance : Int?
    let photoUrl : String?
    let isLiked : Bool?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(googlePlaceId)
        hasher.combine(name)
        hasher.combine(url)
        hasher.combine(distance)
        hasher.combine(photoUrl)
        hasher.combine(isLiked)
    }
}

