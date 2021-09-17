//
//  hungriesApp.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/11/21.
//

import SwiftUI
import GoogleMaps
import GooglePlaces
import Firebase
import SwiftyBeaver


let log = SwiftyBeaver.self

var location = Location()

var authState = AuthState()

class AppDelegate: NSObject, UIApplicationDelegate    {
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            // logging
            let console = ConsoleDestination()  // log to Xcode Console
            let file = FileDestination()  // log to default swiftybeaver.log file
            console.format = "$DHH:mm:ss$d $L $M $X"
            log.addDestination(console)
            log.addDestination(file)
        
    
            // google services
            GMSServices.provideAPIKey(Bundle.main.infoDictionary!["GMS_SERVICES_API_KEY"] as! String)
            GMSPlacesClient.provideAPIKey(Bundle.main.infoDictionary!["GMS_SERVICES_API_KEY"] as! String)
            
            // firebase
            FirebaseApp.configure()
        
            return true
     }
 }

@main
struct HungriesApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
