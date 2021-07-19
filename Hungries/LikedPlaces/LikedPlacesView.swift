//
//  LikedPlacesView.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 6/15/21.
//

import Foundation
import SwiftUI

struct LikedPlacesView {
    
    var places = [Place]()
    
    init(places: [Place]) {
        self.places = places
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(0 ..< places.count, id: \.self) { i in
                    LikedPlaceRow(place: places[i])
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    
}
