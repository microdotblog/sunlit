//
//  AppDelegate.swift
//  Sunlit
//
//  Created by Jonathan Hays on 4/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		let clearCacheKey = "CacheClearKey-" +  (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + "-" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
		var shouldClearCache = true
		// Comment this out to test a fresh install scenario...
		shouldClearCache = UserDefaults.standard.bool(forKey: clearCacheKey) != true

		if shouldClearCache {
			UUDataCache.shared.clearCache()
		}
		UserDefaults.standard.setValue(true, forKey: clearCacheKey)
		
		// Content should only hang around for a day...
		UUDataCache.shared.contentExpirationLength = 24.0 * 60.0 * 60.0
		UUDataCache.shared.purgeExpiredData()
		
		// We might want to change this in the future but for now, it covers basically a single view in one of the collection views
		UURemoteData.shared.maxActiveRequests = 8
		UUHttpRequest.defaultTimeout = 30.0
		UUHttpRequest.defaultCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

		return true
	}
	
	// MARK: UISceneSession Lifecycle

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


}

