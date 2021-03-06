//
//  Auth.swift
//  Hungries
//
//  Created by Stanislav Miachenkov on 8/22/21.
//

import Foundation
import SwiftUI
import CryptoKit
import AuthenticationServices
import Firebase
import FirebaseAuth


struct AuthScreenView: View {
    
    @State var currentNonce: String?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            SignInWithAppleButton(
                onRequest: { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                },
                onCompletion: {result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            guard let nonce = currentNonce else {
                                fatalError("Invalid state: A login callback was received, but no login request was sent.")
                            }
                            guard let appleIDToken = appleIDCredential.identityToken else {
                                fatalError("Invalid state: A login callback was received, but no login request was sent.")
                            }
                            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                log.error("Unable to serialize token string", context: appleIDToken.debugDescription)
                                return
                            }
                            
                            let credential = OAuthProvider.credential(withProviderID: "apple.com",idToken: idTokenString,rawNonce: nonce)
                            Auth.auth().signIn(with: credential) { (authResult, error) in
                                if (error != nil) {
                                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                                    // you're sending the SHA256-hashed nonce as a hex string with
                                    // your request to Apple.
                                    log.error(error?.localizedDescription as Any)
                                    return
                                }
                                log.info("signed in")
                            }
                            authState.authChecked = true
                            authState.firebaseUser = Auth.auth().currentUser
                        default:
                            break
                            
                        }
                    default:
                        break
                    }
                    
                }
            ).frame(width: 280, height: 45, alignment: .center)
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Button(action: {
                authState.authChecked = true
            }) {
                Text("Continue without authorization")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding()
                
            }.overlay(
                RoundedRectangle(cornerRadius: 90)
                    .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2.0)
            ).font( .system(size: 18))
            
            Spacer()
        }
    }
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    return hashString
}


private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}



struct AuthScreenView_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            AuthScreenView().preferredColorScheme($0)
        }
    }
}
