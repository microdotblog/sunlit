//
//  MainViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/22/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//
 
import UIKit
import SafariServices
import AVFoundation
import Snippets

class MainViewController: UIViewController {
	

	@IBOutlet var menuVersionLabel : UILabel!
	@IBOutlet var menuView : UIView!

	var loginViewController : LoginViewController?
	var phoneViewController : MainPhoneViewController?
	var discoverViewController : DiscoverViewController!
	var timelineViewController : TimelineViewController!
	var profileViewController : MyProfileViewController!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.setupNavigationBar()
		self.setupSnippets()
		self.loadContentViews()
		
		if UIDevice.current.userInterfaceIdiom == .pad {
			self.onTabletShowTimeline()
		}
		else {
			self.constructPhoneInterface()
		}
	}
		
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupSnippets() {
		let blogIdentifier = PublishingConfiguration.current.getBlogIdentifier()
		if let token = Settings.snippetsToken() {
			Snippets.shared.configure(permanentToken: token, blogUid: blogIdentifier)
		}
	}


	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupNavigationBar() {

		if UIDevice.current.userInterfaceIdiom == .phone {
			let postButton = UIBarButtonItem(image: UIImage(named: "post"), style: .plain, target: self, action: #selector(onNewPost))
			let settingsButton = UIBarButtonItem(image: UIImage(named: "settings_icon"), style: .plain, target: self, action: #selector(onSettings))
			self.navigationItem.title = "Timeline"
			self.navigationItem.leftBarButtonItem = settingsButton
			self.navigationItem.rightBarButtonItem = postButton
		}
		else if UIDevice.current.userInterfaceIdiom == .pad {
			self.navigationController?.setNavigationBarHidden(true, animated: false)
		}

	}

	
	func loadContentViews() {
		let storyboard = UIStoryboard(name: "Content", bundle: nil)
		self.timelineViewController = storyboard.instantiateViewController(identifier: "TimelineViewController")
		self.profileViewController = storyboard.instantiateViewController(identifier: "MyProfileViewController")
		self.discoverViewController = storyboard.instantiateViewController(identifier: "DiscoverViewController")
	}
	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: .temporaryTokenReceivedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowLoginNotification), name: .showLoginNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleOpenURLNotification(_:)), name: NSNotification.Name("OpenURLNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowCurrentUserProfileNotification), name: .showCurrentUserProfileNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowTimelineNotification), name: .showTimelineNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowDiscoverNotification), name: .showDiscoverNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowComposeNotification), name: .showComposeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleShowSettingsNotification), name: .showSettingsNotification, object: nil)

	}

	@objc func handleOpenURLNotification(_ notification : Notification) {
		if let path = notification.object as? String,
			let url = URL(string: path){
			
			let safariViewController = SFSafariViewController(url: url)
			self.present(safariViewController, animated: true, completion: nil)
		}
	}
	
	@objc func handleShowLoginNotification() {
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
		self.loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")
		self.present(self.loginViewController!, animated: true, completion: nil)
	}

	@objc func handleTemporaryTokenReceivedNotification(_ notification : Notification) {
		if let temporaryToken = notification.object as? String
		{
			Snippets.shared.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
				if let permanentToken = token
				{
					
					// Save our info and setup Snippets
					Settings.saveSnippetsToken(permanentToken)
					Snippets.shared.configure(permanentToken: permanentToken, blogUid: nil)

					// We can hide the login view now...
					DispatchQueue.main.async {
						self.loginViewController?.dismiss(animated: true, completion: nil)
						self.timelineViewController.prepareToDisplay()
					}
					
					Snippets.shared.fetchCurrentUserInfo { (error, updatedUser) in
						
						if let user = updatedUser {
							_ = SnippetsUser.saveAsCurrent(user)
							
							Dialog(self).selectBlog()

							NotificationCenter.default.post(name: .currentUserUpdatedNotification, object: nil)
						}
					}
				}
			}
		}
	}
		
	@objc func handleShowCurrentUserProfileNotification() {
		self.onTabletShowProfile()
	}

	@objc func handleShowTimelineNotification() {
		self.onTabletShowTimeline()
	}

	@objc func handleShowDiscoverNotification() {
		self.onTabletShowDiscover()
	}

	@objc func handleShowComposeNotification() {
		self.onNewPost()
	}

	@objc func handleShowSettingsNotification() {
		self.onSettings()
	}

	
	@IBAction @objc func onNewPost() {
		let pickerController = UIImagePickerController()
		pickerController.modalPresentationCapturesStatusBarAppearance = true
		pickerController.delegate = self
		pickerController.allowsEditing = false
		pickerController.mediaTypes = ["public.image", "public.movie"]
		pickerController.sourceType = .savedPhotosAlbum
		self.present(pickerController, animated: true, completion: nil)
	}
	

	
	@IBAction @objc func onSettings() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
		let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
		
		let navigationController = UINavigationController(rootViewController: settingsViewController)
		self.present(navigationController, animated: true, completion: nil)
	}
	

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func clearPreviousContentViews() {
		self.timelineViewController.removeFromParent()
		self.discoverViewController.removeFromParent()
		self.profileViewController.removeFromParent()
		
		self.timelineViewController.view.removeFromSuperview()
		self.discoverViewController.view.removeFromSuperview()
		self.profileViewController.view.removeFromSuperview()
	}
	
	func onTabletShowTimeline() {
		self.clearPreviousContentViews()
		
		self.addChild(self.timelineViewController)
		self.view.addSubview(self.timelineViewController.view)
		self.view.constrainAllSides(self.timelineViewController.view)
	}
	
	func onTabletShowDiscover() {
		self.clearPreviousContentViews()
		
		self.addChild(self.discoverViewController)
		self.view.addSubview(self.discoverViewController.view)
		self.view.constrainAllSides(self.discoverViewController.view)
	}

	func onTabletShowProfile() {
		self.clearPreviousContentViews()
		
		self.addChild(self.profileViewController)
		self.view.addSubview(self.profileViewController.view)
		self.view.constrainAllSides(self.profileViewController.view)
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func constructPhoneInterface() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Main-Phone", bundle: nil)
		
		if let phoneViewController = storyBoard.instantiateViewController(withIdentifier: "MainPhoneViewController") as? MainPhoneViewController{
			self.phoneViewController = phoneViewController
			phoneViewController.timelineViewController = self.timelineViewController
			phoneViewController.discoverViewController = self.discoverViewController
			phoneViewController.profileViewController = self.profileViewController

			self.addChild(phoneViewController)
			self.view.addSubview(phoneViewController.view)
			phoneViewController.view.bounds = self.view.bounds
		}
	}
	
	
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var media : SunlitMedia? = nil

		if let image = info[.editedImage] as? UIImage {
			media = SunlitMedia(withImage: image)
		}
		else if let image = info[.originalImage] as? UIImage {
			media = SunlitMedia(withImage: image)
		}
		else if let video = info[.mediaURL] as? URL {
			media = SunlitMedia(withVideo: video)
		}

		
		if let media = media {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Compose", bundle: nil)
			let postViewController = storyBoard.instantiateViewController(withIdentifier: "ComposeViewController") as! ComposeViewController
			postViewController.addMedia(media)
			picker.pushViewController(postViewController, animated: true)
		}
		else {
			picker.dismiss(animated: true, completion: nil)
		}
	}
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UISplitViewControllerDelegate {
	func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
		return nil
	}

	func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
		return nil
	}
}

