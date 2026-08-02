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

	private func setupStandaloneMainView() {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
		let navigationController = UINavigationController(rootViewController: mainViewController)
		self.window?.rootViewController = navigationController
	}
	
	func setupMainView() {
		if let navigationController = self.window?.rootViewController as? UINavigationController,
		   navigationController.viewControllers.first is MainViewController {
			return
		}

		self.setupStandaloneMainView()
	}
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let _ = (scene as? UIWindowScene) else { return }

		self.setupColor()
		self.setupMainView()
		self.window?.rootViewController?.loadViewIfNeeded()

		let launchURLs = connectionOptions.urlContexts.map(\.url)
		DispatchQueue.main.async {
			for url in launchURLs {
				SceneDelegate.handleURL(url)
			}
		}
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
		for urlContext in URLContexts {
			SceneDelegate.handleURL(urlContext.url)
		}
	}

	@discardableResult
	static func handleURL(_ url : URL) -> Bool {
		guard url.scheme?.lowercased() == "sunlit",
			  let host = url.host?.lowercased() else {
			return false
		}

		switch host {
		case "show":
			handleShowURL(url)
			return true

		case "notification":
			MainPhoneViewController.needsMentionsSwitch = true
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: .showMentionsNotification, object: nil)
			}
			return true

		case "micropub":
			let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
			let queryItems = components?.queryItems ?? []
			if queryItems.contains(where: { $0.name == "code" }) {
				DispatchQueue.main.async {
					NotificationCenter.default.post(name: .micropubTokenReceivedNotification, object: url)
				}
				return true
			}

			let pathComponents = url.path.split(separator: "/", omittingEmptySubsequences: true)
			guard pathComponents.count == 1,
				  queryItems.isEmpty,
				  Settings.snippetsToken() == nil,
				  Settings.consumePendingSnippetsSignIn() else {
				return false
			}

			let token = String(pathComponents[0])
			guard !token.isEmpty else {
				return false
			}

			DispatchQueue.main.async {
				NotificationCenter.default.post(name: .temporaryTokenReceivedNotification, object: token)
			}
			return true

		default:
			return false
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
