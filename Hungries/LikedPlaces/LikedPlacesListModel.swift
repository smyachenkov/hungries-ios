//
//  LikedPlacesListModel.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 6/14/21.
//

import Foundation
import CoreLocation
import SwiftUI
import Firebase


class LikedPlacesListModel: ObservableObject {
    
    let apiUserName = Bundle.main.infoDictionary!["HUNGRIES_API_USERNAME"] as! String
    
    let apiPassword = Bundle.main.infoDictionary!["HUNGRIES_API_PASSWORD"] as! String
    
    @Published var places = [LocalizedPlace]()
    
    @Published var isLoaded = false
    
    @ObservedObject var auth = authState
    
    var firebaseRdRef = Database.database().reference()
    
    init() {
    }
    
    public func fetchLikedPlaces(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        self.isLoaded = false
        self.places.removeAll()
        if (auth.isLoggedIn()) {
            getLikedPlacesFromFirebase()
        } else {
            getLikedPlacesFromUserDefaults()
        }
    }
    
    private func getLikedPlacesFromFirebase() {
        let fireBaseUserID = auth.firebaseUser!.uid
    
        firebaseRdRef
            .child("users/\(fireBaseUserID)/ratings/liked/")
            .observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot {
                            let placeId = childSnapshot.key

                            // fetch place from places collection
                            self.firebaseRdRef
                                .child("places/\(placeId)")
                                .observeSingleEvent(of: .value, with: { (placeSnapshot) in
                                    if placeSnapshot.exists() {
                                        let placeSnapshotVal = placeSnapshot.value as? NSDictionary
                                        let place = Place(
                                            place_id: placeSnapshotVal?["place_id"] as? String,
                                            name: placeSnapshotVal?["name"] as? String,
                                            rating: placeSnapshotVal?["rating"] as? Double,
                                            vicinity: placeSnapshotVal?["vicinity"] as? String,
                                            geometry: GeometryModel(
                                                location: LocationModel(
                                                    lat: placeSnapshotVal?.value(forKeyPath: "geometry.location.lat") as? Double,
                                                    lng: placeSnapshotVal?.value(forKeyPath: "geometry.location.lng") as? Double
                                                )
                                            )
                                        )
                                        let distanceTo = location.distanceFrom(place: place)
                                        self.places.append(
                                            LocalizedPlace(
                                                place: place,
                                                isLiked: true,
                                                distance: distanceTo
                                            )
                                        )
                                    } else {
                                        log.info("can't find saved place", context: placeId)
                                    }
                                })
                        }
                    }
                } else {
                    log.info("No liked places for user", context: fireBaseUserID)
                }
                self.isLoaded = true
            })
    }
    
    private func getLikedPlacesFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "likedPlaces") {
            do {
                let decoder = JSONDecoder()
                let storedPlaces = try decoder.decode([Place].self, from: data)
                storedPlaces.forEach {p in
                    let distanceTo = location.distanceFrom(place: p)
                    self.places.append(
                        LocalizedPlace(
                            place: p,
                            isLiked: true,
                            distance: distanceTo
                        )
                    )
                }
            } catch {
                log.info("Unable to Decode Places", context: error)
            }
            self.isLoaded = true
        }
    }
}
