//
//  LoadingProgressCard.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 6/10/21.
//

import Foundation


import Foundation
import SwiftUI
import CoreLocation
import GoogleMaps


struct LoadingProgressCard: View {

    var body: some View {
        GeometryReader { geometry in
                VStack(alignment: .leading) {
                    Text("Loading...")
                        .frame(width: geometry.size.width)
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.95)
                .padding(.bottom)
                .background(Color.white)
                .cornerRadius(10)
            }
    }
}
