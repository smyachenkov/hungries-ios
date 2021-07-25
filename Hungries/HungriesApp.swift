//
//  hungriesApp.swift
//  hungries
//
//  Created by Stanislav Miachenkov on 5/11/21.
//

import SwiftUI
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate    {
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            GMSServices.provideAPIKey(Bundle.main.infoDictionary!["GMS_SERVICES_API_KEY"] as! String)
            return true
     }
 }

let deviceId: String = UIDevice.current.identifierForVendor!.uuidString

@main
struct HungriesApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}