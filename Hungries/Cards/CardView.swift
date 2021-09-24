//
//  CardView.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/17/21.
//

import Foundation
import SwiftUI
import CoreLocation
import GoogleMaps
import GooglePlaces


struct CardView: View {
    @State private var translation: CGSize = .zero
    @State private var swipeStatus: LikeDislike = .none
    
    @ObservedObject var imageLoader: ImageLoader
    
    @Environment(\.colorScheme) var colorScheme
    
    private var localizedPlace: LocalizedPlace
    
    private var thresholdPercentage: CGFloat = 0.4
    
    private var onSwipe: (Bool) -> Void
    
    private enum LikeDislike: Int {
        case like, dislike, none
    }
    
    init(localizedPlace: LocalizedPlace, onSwipe: @escaping (Bool) -> Void) {
        self.localizedPlace = localizedPlace
        self.onSwipe = onSwipe
        self.imageLoader = ImageLoader(googlePlaceId: localizedPlace.place.place_id)
        // todo move to onAppear()
        imageLoader.load()
    }
    
    private func getGesturePercentage(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> CGFloat {
        gesture.translation.width / geometry.size.width
    }
    
    
    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(alignment: .top) {
                    Text("LIKE")
                        .font(.headline)
                        .padding()
                        .cornerRadius(10)
                        .foregroundColor(Color.green)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 5.0)
                        ).padding(20)
                        .rotationEffect(Angle.degrees(-45))
                    
                    Spacer()
                    
                    Text("SKIP")
                        .font(.headline)
                        .padding()
                        .cornerRadius(10)
                        .foregroundColor(Color.red)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 5.0)
                        ).padding(20)
                        .rotationEffect(Angle.degrees(45))
                }
                VStack(alignment: .leading) {
                    ZStack {
                        VStack {
                            if (self.imageLoader.image != nil) {
                                Image(uiImage: self.imageLoader.image!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            
                            Text(self.localizedPlace.place.name!)
                            
                            HStack {
                                
                                VStack {
                                    
                                    // Main info
                                    HStack {
                                        // todo move to common class
                                        Link(destination: URL(string: "https://www.google.com/maps/search/?api=1&query=Google&query_place_id=" + localizedPlace.place.place_id!)!,
                                             label: {
                                                Text("Open in maps").underline()
                                             })
                                        
                                        Text("\(localizedPlace.distance!)m")
                                            .padding(.trailing, 40)
                                        
                                        Spacer()
                                        
                                        if (localizedPlace.place.rating != nil) {
                                            Text("\((localizedPlace.place.rating!).description)")
                                            Image(systemName: "star.fill")
                                        }
                                    }
                                    
                                    Divider().padding(.horizontal, 10)
                                    
                                    // Address
                                    HStack {
                                        Text("\(localizedPlace.place.vicinity ?? "")")
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer()
                                    }
                                    
                                }.padding()
                            }.frame(width: geometry.size.width)
                        }
                        VStack {
                            HStack {
                                
                                Spacer()
                                
                                Spacer()
                                
                                // todo replace with hand.thumbsup.circle
                                // todo display for unauthorized users too
                                if (self.localizedPlace.isLiked != nil) {
                                    if (self.localizedPlace.isLiked!) {
                                        Image(systemName: "hand.thumbsup.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 32))
                                            .padding(20)
                                    } else {
                                        Image(systemName: "hand.thumbsdown.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 32))
                                            .padding(20)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.95)
                .padding(.bottom)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .animation(.interactiveSpring())
                .offset(x: self.translation.width, y: 0)
                .rotationEffect(.degrees(Double(self.translation.width / geometry.size.width) * 25), anchor: .bottom)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.translation = value.translation
                            if (self.getGesturePercentage(geometry, from: value)) >= self.thresholdPercentage {
                                self.swipeStatus = .like
                            } else if self.getGesturePercentage(geometry, from: value) <= -self.thresholdPercentage {
                                self.swipeStatus = .dislike
                            } else {
                                self.swipeStatus = .none
                            }
                            
                        }.onEnded { value in
                            self.translation = .zero
                            if abs(self.getGesturePercentage(geometry, from: value)) > self.thresholdPercentage {
                                self.onSwipe(self.swipeStatus == .like)
                                self.swipeStatus = .none
                            }
                        }
                )
            }.background(
                swipeStatus == .none ?
                    (colorScheme == .dark ? Color.black : Color.white) : (swipeStatus == .like ? Color.green : Color.red)
            )
        }
    }
}


struct CardView_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            CardView(
                localizedPlace: LocalizedPlace(
                    place: Place(place_id: "123",
                                 name: "Crispy Coffee",
                                 rating: 4.5,
                                 vicinity: "12, Carl st, Columbia, Canada",
                                 geometry: GeometryModel(
                                    location: LocationModel(
                                        lat: 55.3454,
                                        lng: 37.3123
                                    )
                                 )
                    ),
                    isLiked: true,
                    distance: 100
                ),
                onSwipe: {
                    (liked: Bool) -> ()  in
                    print(liked)
                }
            ).preferredColorScheme($0)
        }
    }
}
