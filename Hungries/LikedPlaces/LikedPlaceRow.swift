//
//  LikedPlaceRow.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 6/15/21.
//

import Foundation
import SwiftUI

struct LikedPlaceRow: View {
    
    var place: Place
 
    
    init(place: Place) {
        self.place = place
    }
    
    var body: some View {
        HStack {
            Link(destination: URL(string: place.url!)!,
                 label: {
                    Text(place.name!).underline()
                 }).padding(10)
            Spacer()
            Text("\(place.distance!)m")
        }.padding(20)
        .border(Color.gray)
    }
}
