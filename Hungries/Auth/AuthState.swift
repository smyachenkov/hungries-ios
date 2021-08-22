//
//  AuthUserData.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 8/22/21.
//

import Foundation
import FirebaseAuth

class AuthState: ObservableObject {
    
    @Published var authChecked = false
    
    @Published var firebaseUser: User?
    
}

