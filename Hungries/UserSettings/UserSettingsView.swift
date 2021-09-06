//
//  UserSettingsView.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 9/5/21.
//

import SwiftUI

let SETTINGS_KEY_SEARCH_RADIUS = "settings.searchRadius"

struct UserSettingsView: View {
    
    @AppStorage(SETTINGS_KEY_SEARCH_RADIUS) var searchRadius: Int = 500
    
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            return Double(searchRadius)
        }, set: {
            searchRadius = Int($0)
        })
    }
    
    var body: some View {
        
        VStack{
            Text("Settings")
                .font(.title2)
                .padding(.vertical, 10)

            HStack {
                Spacer()
                Text("Radius")
                
                Slider(value: intProxy , in: 100.0...1000.0, step: 50.0)
                
                Text("\(searchRadius.description)m")
            }.padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.top, 20)
            
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)

    }
}


struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            UserSettingsView().preferredColorScheme($0)
        }

    }
}
