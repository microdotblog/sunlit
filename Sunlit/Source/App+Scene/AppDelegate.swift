//
//  AppDelegate.swift
//  Sunlit
//
//  Created by Jonathan Hays on 4/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwiftNetworking
import Snippets

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let token = Settings.snippetsToken() {
            Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: token)
        }

		if let options = launchOptions,
		   let url = options[.url] as? URL,
		   url.host == "show" {
			DispatchQueue.main.async {
				SceneDelegate.handleShowURL(url)
			}
		}

		/*
		let clearCacheKey = "CacheClearKey-" +  (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + "-" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
		var shouldClearCache = true
		// Comment this out to test a fresh install scenario...
        shouldClearCache = Settings.bool(forKey: clearCacheKey) != true

		if shouldClearCache {
			UUDataCache.shared.clearCache()
		}
        Settings.setValue(true, forKey: clearCacheKey)
		
		// Content should only hang around for a day...
		UUDataCache.shared.contentExpirationLength = 24.0 * 60.0 * 60.0
		UUDataCache.shared.purgeExpiredData()
		*/

		// We might want to change this in the future but for now, it covers basically a single view in one of the collection views
		UURemoteData.shared.maxActiveRequests = 8
		UUHttpRequest.defaultTimeout = 30.0
		UUHttpRequest.defaultCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

		BlogSettings.migrate()

        UNUserNotificationCenter.current().delegate = self

        if let _ = launchOptions?[.remoteNotification] {
            MainPhoneViewController.needsMentionsSwitch = true
        }

		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		if url.host == "show" {
			DispatchQueue.main.async {
				SceneDelegate.handleShowURL(url)
			}
		}
		return true
	}
	
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
		let token = tokenParts.joined()

		var fullPath : NSString = Snippets.Configuration.timeline.microblogEndpoint as NSString
		fullPath = fullPath.appendingPathComponent("/users/push/register") as NSString


		let arguments : [ String : String ] = [ "device_token" : token,
												"push_env" : "production",
												"app_name" : "Sunlit" ]

		let request = Snippets.securePost(Snippets.Configuration.timeline, path: fullPath as String, arguments: arguments)

		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
		})


	}

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if application.applicationState != .active {
            if let url = URL(string:"sunlit://notification") {
                application.open(url, options: [:], completionHandler: nil)
            }

            //DispatchQueue.main.async {
            //    NotificationCenter.default.post(name: .showMentionsNotification, object: userInfo)
            //}
        }

        SunlitMentions.shared.update {
            completionHandler(.newData)
        }
	}

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("Got here!")
    }


}


extension AppDelegate : UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showMentionsNotification, object: nil)
        }

        NotificationCenter.default.post(name: .showMentionsNotification, object: nil)

        // tell the app that we have finished processing the user’s action / response
        completionHandler()
      }
}
