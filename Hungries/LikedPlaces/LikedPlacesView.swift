//
//  LikedPlacesView.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 8/1/21.
//
import Foundation
import SwiftUI

struct LikedPlacesView: View {
    
    var places = [Place]()
        
    @State var showRemoveDialog = false
        
    @Environment(\.colorScheme) var colorScheme

    init(places: [Place]) {
        self.places = places
    }
    
    var body: some View {
        VStack {
            
            Text("Liked Places")
                .font(.title2)
                .padding(.vertical, 10)
            
            ScrollView(.vertical) {
                //VStack(spacing: 10) {
                //https://stackoverflow.com/questions/60009646/mysterious-spacing-or-padding-in-elements-in-a-vstack-in-a-scrollview-in-swiftui
                VStack(spacing: 0) {
                    ForEach(0 ..< self.places.count, id: \.self) { i in
                        HStack {
                            // place info
                            HStack {
                                Link(
                                    destination: URL(string: places[i].url!)!,
                                    label: {
                                        Text(places[i].name!).underline()
                                     })
                                Spacer()
                                Text("\(places[i].distance!)m")
                            }
                            
                            Spacer()
                            
                            // remove button
                            Button("❌") {
                                showRemoveDialog.toggle()
                            }.alert(isPresented: $showRemoveDialog) {
                                Alert(
                                    title: Text("Do you want to remove this place from liked?"),
                                    message: Text("You can like it again when you see it"),
                                    primaryButton: .destructive(Text("Remove")) {
                                        // todo implement
                                        // remove from places array here and send request to backend
                                    },
                                    secondaryButton: .cancel()
                                )
                            }.padding(.horizontal, 10)
                        }.padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        
                        
                        Divider().padding(.horizontal, 10)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct LikedPlacesView_Previews: PreviewProvider {
    
    static var previews: some View {
        let testPlaces = [
            Place(id: 1, name: "Dirty Coffee", url: "google.com", distance: 100, photoUrl: "", isLiked: true),
            Place(id: 1, name: "Night Pizza", url: "google.com", distance: 200, photoUrl: "", isLiked: true)
        ]
        ForEach(ColorScheme.allCases, id: \.self) {
            LikedPlacesView(places: testPlaces).preferredColorScheme($0)
        }
    }
}


