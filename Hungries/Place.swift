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

struct Place: Decodable {
    let id : Int?
    let name : String?
    let url : String?
    let distance : Int?
    let photoUrl : String?
    let isLiked : Bool?
}
