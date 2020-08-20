//
//  AppDelegate.swift
//  Gossp
//
//  Created by Kaan Karay on 2.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseCore
import FirebaseUI
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FUIAuthDelegate {
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
    let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
    application.registerUserNotificationSettings(pushNotificationSettings)
    application.registerForRemoteNotifications()
    // Override point for customization after application launch.
    GMSServices.provideAPIKey(GMSMapsSDKkey)
    GMSPlacesClient.provideAPIKey(GMSPlacesSDKkey)
    FirebaseApp.configure()
    
    //MARK: OneSignal
    //OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
    let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false, kOSSettingsKeyInAppLaunchURL: false]
    
    OneSignal.initWithLaunchOptions(launchOptions,
                                    appId: "2779a69a-5ec9-44fa-8a7d-5503f3298a8c",
                                    handleNotificationAction: nil,
                                    settings: onesignalInitSettings)
    
    OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
    OneSignal.promptForPushNotifications(userResponse: { accepted in
      print("User accepted notifications: \(accepted)")
    })
    //END OneSignal initializataion code
    
    
    UITabBar.appearance().barTintColor = .gosspLighterPurple
    UITabBar.appearance().tintColor = .gosspGreen
    UITabBar.appearance().unselectedItemTintColor = UIColor.white
    UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
    UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gosspGreen], for: .selected)
    
    
    return true
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    // Else, this notification is not auth related, handle it.
    
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
    if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
      return true
    }
    // other URL handling goes here.
    return false
  }
  
  
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    FUIAuth.defaultAuthUI()?.auth?.setAPNSToken(deviceToken, type: AuthAPNSTokenType.prod)
    // Pass device token to auth
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
  }
  
  
  
  
  
}

