//
//  LastCardView.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 6/8/21.
//

import Foundation


import Foundation
import SwiftUI
import CoreLocation
import GoogleMaps


struct LastCardView: View {

    @EnvironmentObject var settings: UserSettings
    
    private var reloadAction: () -> Void

    init(reloadAction: @escaping () -> Void) {
        self.reloadAction = reloadAction
    }


    var body: some View {
        GeometryReader { geometry in
                VStack(alignment: .leading) {
                    VStack() {
                        Text("Can't find more!")
                            .frame(width: geometry.size.width)
                                            
                        // reset
                        Button("Start againg 🔄") {
                            self.reloadAction()
                        }.font(.title)
                        .background(Color.white)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.95)
                .padding(.bottom)
                .background(Color.white)
                .cornerRadius(10)
            }
    }
}
