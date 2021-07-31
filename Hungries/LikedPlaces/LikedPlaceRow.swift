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
    
    @Environment(\.colorScheme) var colorScheme
    
    init(place: Place) {
        self.place = place
    }
    
    var body: some View {
        HStack {
            Link(destination: URL(string: place.url!)!,
                 label: {
                    Text(place.name!).underline()
                 })
            Spacer()
            Text("\(place.distance!)m")
        }.padding(.horizontal, 20)
        .padding(.vertical, 10)
        .border(colorScheme == .dark ? Color.white : Color.gray)
    }
}


struct LikedPlaceRow_Preview : PreviewProvider {
    
    static var previews: some View {
        
        let testPlace = Place(
            id: 1,
            name: "Black Coffee",
            url: "google.com",
            distance: 100,
            photoUrl: nil,
            isLiked: true
        )
        
        ForEach(ColorScheme.allCases, id: \.self) {
            LikedPlaceRow(place: testPlace).preferredColorScheme($0)
        }
        
    }
}

