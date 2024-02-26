//
//  SceneDelegate.swift
//  Sunlit
//
//  Created by Jonathan Hays on 4/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import UUSwift
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func setupColor() {
		self.window?.tintColor = UIColor(named: "color_tab_selected")
	}
	
	func setupSplitView() {
        guard let splitViewController =  window?.rootViewController // UIApplication.shared.windows[0].rootViewController
		  as? UISplitViewController else {
		  fatalError("Missing SplitViewController")
		}
		
		guard let contentNavigationController = splitViewController.viewControllers.last as? UINavigationController,
              let menuNavigationController = splitViewController.viewControllers.first as? UINavigationController
			//let mainViewController = navigationController.topViewController as? MainViewController
			else {
				fatalError("Missing Main View Controller")
			}

        guard //let contentViewController = contentNavigationController.visibleViewController as? MainViewController,
              let menuViewController = menuNavigationController.visibleViewController as? MainTabletViewController else {
            fatalError("Storyboard corrupted")
        }

        menuViewController.contentViewController = contentNavigationController
        
        splitViewController.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
		splitViewController.presentsWithGesture = false
		
		if UIDevice.current.userInterfaceIdiom == .phone {
			splitViewController.viewControllers = [contentNavigationController, contentNavigationController]
		}
	}
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let _ = (scene as? UIWindowScene) else { return }

		self.setupColor()
		self.setupSplitView()
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
	}

	func sceneWillResignActive(_ scene: UIScene) {
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
        if #available(iOS 14, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "blog.micro.sunlit.widget")
        }
	}
	
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		if let urlContext = URLContexts.first {
			let url = urlContext.url
            if url.host == "show" {
				SceneDelegate.handleShowURL(url)
                return
            }
            else if url.absoluteString.contains("notification") {
                MainPhoneViewController.needsMentionsSwitch = true

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .showMentionsNotification, object: nil)
                }
            }
			else if url.absoluteString.contains("micropub?code=") {
				DispatchQueue.main.async {
					NotificationCenter.default.post(name: .micropubTokenReceivedNotification, object: url)
				}
			}
			else {
				let token = url.lastPathComponent
				if token.count > 0 {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: .temporaryTokenReceivedNotification, object: token)
					}
				}
			}
		}
	}


    static func handleShowURL(_ url : URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {

            if let items = components.queryItems {
                for q in items {
                    if q.name == "id",
					   let identifier = q.value,
					   identifier.count > 0 {

                        let sunlitPost = SunlitPost()
                        sunlitPost.identifier = identifier
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .viewConversationNotification, object: sunlitPost)
                        }
                    }
                }
            }
        }
    }
}

