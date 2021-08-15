//
//  ImageLoader.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 8/15/21.
//

import Foundation
import SwiftUI
import GooglePlaces
import GoogleMaps

class ImageLoader: ObservableObject {
    
    @Published var image: UIImage?
    
    private let googlePlaceId: String?

    init(googlePlaceId: String?) {
        self.googlePlaceId = googlePlaceId
    }

    func load() {
        if (googlePlaceId != nil) {
            let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.photos.rawValue))
            GMSPlacesClient.shared().fetchPlace(fromPlaceID: googlePlaceId!,
                                                placeFields: fields,
                                                sessionToken: nil) {
                (place: GMSPlace?, error: Error?) in
                if let error = error {
                    print("Error requesting photos: \(error.localizedDescription)")
                    return
                  }
                if let place = place {
                    if (place.photos == nil || place.photos?.count == 0) {
                        // todo make default placeholder for place without photo
                        return
                    }
                    let firstPhotoMetaData: GMSPlacePhotoMetadata = place.photos![0]
                    GMSPlacesClient.shared().loadPlacePhoto(firstPhotoMetaData, callback: { (photo, error) -> Void in
                        if let error = error {
                            print("Error loading photo metadata: \(error.localizedDescription)")
                            return
                        } else {
                            self.image = photo
                        }
                    })
                }
            }
        }
    }
}
