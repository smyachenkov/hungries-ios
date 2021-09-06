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
    
    private var reloadAction: () -> Void

    init(reloadAction: @escaping () -> Void) {
        self.reloadAction = reloadAction
    }


    var body: some View {
        GeometryReader { geometry in
                VStack(alignment: .leading) {
                    VStack {
                        Text("There are no more places here")
                            .frame(width: geometry.size.width)
                                            
                        // reset
                        Button(action: {
                            self.reloadAction()
                        }) {
                            HStack() {
                                Text("Start againg")
                                Image(systemName: "arrow.uturn.backward")
                            }.padding(10)
                        }.overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2.0)
                        ).font( .system(size: 24))
                        
                        // select new location
                        // todo: implement
                
                    }.padding(20)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(.bottom)
                .cornerRadius(10)
            }
    }
}
