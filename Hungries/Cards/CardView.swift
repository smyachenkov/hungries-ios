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


struct CardView: View {
    @State private var translation: CGSize = .zero
    @State private var swipeStatus: LikeDislike = .none

    @EnvironmentObject var settings: UserSettings
    
    @Environment(\.colorScheme) var colorScheme

    private var place: Place

    private var imageData: Data?

    private var thresholdPercentage: CGFloat = 0.4
    private var onSwipe: (Bool) -> Void

    private enum LikeDislike: Int {
        case like, dislike, none
    }

    init(place: Place, imageData: Data?, onSwipe: @escaping (Bool) -> Void) {
        self.place = place
        self.imageData = imageData
        self.onSwipe = onSwipe
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
                            if (self.imageData != nil) {
                                Image(uiImage: UIImage(data: self.imageData!)!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            
                            Text(self.place.name!)
                                .frame(width: geometry.size.width)
                            
                            HStack {
                                Text("Distance: \(self.place.distance!)m")
                                    .padding()
                                Link(destination: URL(string: self.place.url!)!,
                                     label: {
                                        Text("Open in maps").underline()
                                     }).padding()
                            }.frame(width: geometry.size.width)
                        }
                        VStack {
                            HStack {
                                Spacer()
                                Spacer()
                                // todo replace with hand.thumbsup.circle
                                if (self.place.isLiked != nil) {
                                    if (self.place.isLiked!) {
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
