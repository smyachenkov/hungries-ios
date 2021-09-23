//
//  LoadingCardView.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 6/10/21.
//

import Foundation


import Foundation
import SwiftUI
import CoreLocation
import GoogleMaps


struct LoadingCardView: View {

    private var message: String
    
    init(message: String) {
        self.message = message
    }
    
    var body: some View {
        GeometryReader { geometry in
                VStack(alignment: .leading) {
                    Text(message)
                        .frame(width: geometry.size.width)
                    ProgressView()
                        .frame(width: geometry.size.width)
    
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(.bottom)
            }
    }
}

struct LoadingCardView_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            LoadingCardView(message: "Loading...").preferredColorScheme($0)
        }
    }
}
