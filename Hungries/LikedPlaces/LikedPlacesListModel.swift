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
    
    @Published var places = [Place]()
    
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
        self.isLoaded = true
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
                            print("checking place \(placeId)")
                            // fetch place from places collection
                            self.firebaseRdRef
                                .child("places/\(placeId)")
                                .observeSingleEvent(of: .value, with: { (placeSnapshot) in
                                    if placeSnapshot.exists() {
                                        let placeSnapshotVal = placeSnapshot.value as? NSDictionary
                                        // todo update ater migration to Places SDK
                                        let place = Place(
                                            id: 0,
                                            googlePlaceId: placeSnapshotVal?["googleId"] as? String ?? "",
                                            name: placeSnapshotVal?["name"] as? String ?? "",
                                            url: "google.com",
                                            distance: 500,
                                            photoUrl: nil,
                                            isLiked: true
                                        )
                                        self.places.append(place)
                                    } else {
                                        print("can't find saved place \(placeId)")
                                    }
                                })
                        }
                    }
                } else {
                    print("No liked places for user \(fireBaseUserID)")
                }
            })
    }
    
    private func getLikedPlacesFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "likedPlaces") {
            do {
                let decoder = JSONDecoder()
                self.places = try decoder.decode([Place].self, from: data)
            } catch {
                print("Unable to Decode Places (\(error))")
            }
        }
    }
}
