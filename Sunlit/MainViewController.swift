//
//  MainViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/22/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices

class MainViewController: UIViewController {

	@IBOutlet var menuVersionLabel : UILabel!
	@IBOutlet var menuView : UIView!
	var menuDimView : UIButton!

	var tabBar : UITabBar!
	var contentView : UIView!
	var discoverViewController : DiscoverViewController!
	var timelineViewController : TimelineViewController!
	var profileViewController : MyProfileViewController!
	var loginViewController : LoginViewController?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.loadPrimaryViewsFromStoryboards()
		
		self.constructPhoneInterface()
		self.setupSnippets()
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupSnippets() {
		let blogIdentifier = Settings.blogIdentifier()
		if let token = Settings.permanentToken() {
			Snippets.shared.configure(permanentToken: token, blogUid: blogIdentifier)
			self.onShowTimeline()
		}
		else {
			self.onShowLogin()
		}
	}



	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleOpenURLNotification(_:)), name: NSNotification.Name("OpenURLNotification"), object: nil)
	}

	@objc func handleOpenURLNotification(_ notification : Notification) {
		if let path = notification.object as? String,
			let url = URL(string: path){
			
			let safariViewController = SFSafariViewController(url: url)
			self.present(safariViewController, animated: true, completion: nil)
		}
	}
	
	
	@objc func handleTemporaryTokenReceivedNotification(_ notification : Notification) {
		if let temporaryToken = notification.object as? String
		{
			Snippets.shared.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
				if let permanentToken = token
				{
					Settings.savePermanentToken(permanentToken)
					Snippets.shared.configure(permanentToken: permanentToken, blogUid: nil)
					
					Snippets.shared.fetchCurrentUserInfo { (error, updatedUser) in
						
						if let user = updatedUser {
							_ = SnippetsUser.saveAsCurrent(user)
							
							// Go ahead and go get the avatar for the logged in user
							if ImageCache.prefetch(user.pathToUserImage) == nil {
								ImageCache.fetch(user.pathToUserImage) { (image) in
								}
							}
							
							self.onSelectBlogConfiguration()
						}
					}
				}
			}
		}
	}
	
	@objc func onToggleHamburgerMenu() {
		let width : CGFloat = 180.0
		let closedRect = CGRect(x: -width, y: 0.0, width: width, height: self.view.bounds.size.height)
		let openRect = CGRect(x: 0.0, y: 0.0, width: width, height: self.view.bounds.size.height)
		
		if self.menuDimView == nil {
			self.menuDimView = UIButton(type: .custom)
			self.menuDimView.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
			self.menuDimView.addTarget(self, action: #selector(onToggleHamburgerMenu), for: .touchUpInside)
		}
		
		if self.menuView.superview == nil {
			self.menuDimView.frame = self.view.bounds
			self.menuView.frame = closedRect
			self.view.addSubview(self.menuDimView)
			self.view.addSubview(self.menuView)
			self.view.updateConstraints()
			self.view.layoutIfNeeded()
			
			self.menuDimView.alpha = 0.0
			
			var frame = self.contentView.frame
			frame.origin.x = frame.origin.x + 15
			self.menuView.isUserInteractionEnabled = true
			let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(onToggleHamburgerMenu))
			swipeGestureRecognizer.direction = .left
			self.menuView.addGestureRecognizer(swipeGestureRecognizer)
		
			UIView.animate(withDuration: 0.15) {
				self.menuDimView.alpha = 1.0
				//self.contentView.frame = frame
			}
			
			UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: .curveEaseInOut, animations: {
				self.menuView.frame = openRect
				self.contentView.transform = CGAffineTransform(translationX: 10.0, y: 0.0)
			}, completion: nil)
		}
		else {
			var frame = self.contentView.frame
			frame.origin.x = 0
			UIView.animate(withDuration: 0.15, animations: {
				self.menuView.frame = closedRect
				self.menuDimView.alpha = 0.0
				//self.contentView.frame = frame
				self.contentView.transform = CGAffineTransform.identity
			}) { (complete) in
				self.menuView.removeFromSuperview()
				self.menuDimView.removeFromSuperview()
			}
		}
	}
	
	@IBAction func onAbout() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "About", bundle: nil)
		let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "AboutViewController")
		self.present(newPostViewController, animated: true, completion: nil)

		self.onToggleHamburgerMenu()
	}
	
	@IBAction func onDrafts() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Drafts", bundle: nil)
		let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "DraftsViewController")
		self.present(newPostViewController, animated: true, completion: nil)

		self.onToggleHamburgerMenu()
	}
	
	@IBAction func onSettings() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
		let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
		self.present(newPostViewController, animated: true, completion: nil)

		self.onToggleHamburgerMenu()
	}
	
	@objc func onNewPost() {
		let pickerController = UIImagePickerController()
		pickerController.delegate = self
		pickerController.allowsEditing = false
		pickerController.mediaTypes = ["public.image", "public.movie"]
		pickerController.sourceType = .photoLibrary
		self.present(pickerController, animated: true, completion: nil)
	}
	
	@objc func onShowLogin() {
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
		self.loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")
		show(self.loginViewController!, sender: self)
	}
	
	@objc func onShowTimeline() {
		if let loginViewController = self.loginViewController {
			loginViewController.dismiss(animated: true, completion: nil)
			self.loginViewController = nil
		}

		self.discoverViewController.removeFromParent()
		self.discoverViewController.view.removeFromSuperview()
		self.profileViewController.removeFromParent()
		self.profileViewController.view.removeFromSuperview()
		
		self.addChild(timelineViewController)
		self.contentView.addSubview(timelineViewController.view)
		timelineViewController.view.frame = self.contentView.frame

		self.pinToContentView(timelineViewController.view)
	}
	
	@objc func onShowProfile() {
		if let loginViewController = self.loginViewController {
			loginViewController.dismiss(animated: true, completion: nil)
			self.loginViewController = nil
		}
		
 		self.discoverViewController.removeFromParent()
		self.discoverViewController.view.removeFromSuperview()
		self.timelineViewController.removeFromParent()
		self.timelineViewController.view.removeFromSuperview()

		self.addChild(profileViewController)
		self.contentView.addSubview(profileViewController.view)
		profileViewController.view.frame = self.contentView.frame

		self.pinToContentView(profileViewController.view)
	}
	
	@objc func onShowDiscover() {
		self.profileViewController.removeFromParent()
		self.profileViewController.view.removeFromSuperview()
		self.timelineViewController.removeFromParent()
		self.timelineViewController.view.removeFromSuperview()

		self.addChild(discoverViewController)
		self.contentView.addSubview(discoverViewController.view)
		discoverViewController.view.frame = self.contentView.frame

		self.pinToContentView(discoverViewController.view)
	}
	
	@objc func onSelectBlogConfiguration() {
		Snippets.shared.fetchCurrentUserConfiguration { (error, configuration) in
			
			// Check for a media endpoint definition...
			if let mediaEndPoint = configuration["media-endpoint"] as? String {
				Settings.saveMediaEndpoint(mediaEndPoint)
				Snippets.shared.setMediaEndPoint(mediaEndPoint)
			}
			
			DispatchQueue.main.async {

				if let destinations = configuration["destination"] as? [[String : Any]] {
					
					if destinations.count > 1 {
						self.onSelectBlogConfiguration(destinations)
						return
					}
				
					if let destination = destinations.first {
						if let blogIdentifier = destination["uid"] as? String {
							Settings.saveBlogIdentifier(blogIdentifier)
						}
					}
				}
			
				Dialog.information("You have successfully logged in.", self) {
					self.onShowTimeline()
				}
			}
		}
	}
	
	@objc func onSelectBlogConfiguration(_ destinations : [[String : Any]]) {

		let actionSheet = UIAlertController(title: nil, message: "Please select which Micro.blog to use when publishing.", preferredStyle: .actionSheet)

		for destination in destinations {
			if let title = destination["name"] as? String,
				let blogId = destination["uid"] as? String {
				let action = UIAlertAction(title: title, style: .default) { (action) in
					Settings.saveBlogIdentifier(blogId)
					Snippets.shared.setBlogIdentifier(blogId)
					
					Dialog.information("You have successfully logged in.", self) {
						self.onShowTimeline()
					}
				}
				
				actionSheet.addAction(action)
			}
		}
		
		self.present(actionSheet, animated: true) {
		}

	}
	
	func pinToContentView(_ view : UIView) {
		let topConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self.contentView!, attribute: .top, multiplier: 1.0, constant: 0.0)
		let bottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self.contentView!, attribute: .bottom, multiplier: 1.0, constant: 0.0)
		let leftConstraint = NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: self.contentView!, attribute: .left, multiplier: 1.0, constant: 0.0)
		let rightConstraint = NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: self.contentView!, attribute: .right, multiplier: 1.0, constant: 0.0)
		self.contentView.addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
	}
	
	func loadPrimaryViewsFromStoryboards() {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		self.timelineViewController = storyboard.instantiateViewController(identifier: "TimelineViewController")
		self.profileViewController = storyboard.instantiateViewController(identifier: "MyProfileViewController")
		self.discoverViewController = storyboard.instantiateViewController(identifier: "DiscoverViewController")
	}

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func setupPhoneNavigationBar() {
		let hamburgerMenuButton = UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(onToggleHamburgerMenu))
		let postButton = UIBarButtonItem(image: UIImage(named: "post"), style: .plain, target: self, action: #selector(onNewPost))

		self.navigationItem.title = "Timeline"
		self.navigationItem.leftBarButtonItem = hamburgerMenuButton
		self.navigationItem.rightBarButtonItem = postButton
	}

	func setupPhoneContentView() {
		self.contentView = UIView()
		self.view.addSubview(self.contentView)
		self.contentView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.self.width, height: self.view.bounds.size.height)
		self.contentView.translatesAutoresizingMaskIntoConstraints = false
		let topConstraint = NSLayoutConstraint(item: self.contentView!, attribute: .top, relatedBy: .equal, toItem: self.view!, attribute: .top, multiplier: 1.0, constant: 0.0)
		let bottomConstraint = NSLayoutConstraint(item: self.contentView!, attribute: .bottomMargin, relatedBy: .equal, toItem: self.tabBar!, attribute: .top, multiplier: 1.0, constant: -10.0)
		let leftConstraint = NSLayoutConstraint(item: self.contentView!, attribute: .left, relatedBy: .equal, toItem: self.view!, attribute: .left, multiplier: 1.0, constant: 0.0)
		let rightConstraint = NSLayoutConstraint(item: self.contentView!, attribute: .right, relatedBy: .equal, toItem: self.view!, attribute: .right, multiplier: 1.0, constant: 0.0)
		self.view.addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
	}
	
	func setupPhoneTabBar() {
		let tabBarHeight : CGFloat = 90.0

		self.tabBar = UITabBar()
		self.view.addSubview(self.tabBar)
		self.tabBar.frame = CGRect(x: 0, y: self.view.bounds.size.height - tabBarHeight, width: self.view.bounds.size.width, height: tabBarHeight)
		self.tabBar.translatesAutoresizingMaskIntoConstraints = false
		
		let heightConstraint = NSLayoutConstraint(item: self.tabBar!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: tabBarHeight)
		let bottomConstraint = NSLayoutConstraint(item: self.tabBar!, attribute: .bottomMargin, relatedBy: .equal, toItem: self.view!, attribute: .bottomMargin, multiplier: 1.0, constant: 0.0)
		let leftConstraint = NSLayoutConstraint(item: self.tabBar!, attribute: .left, relatedBy: .equal, toItem: self.view!, attribute: .left, multiplier: 1.0, constant: 0.0)
		let rightConstraint = NSLayoutConstraint(item: self.tabBar!, attribute: .right, relatedBy: .equal, toItem: self.view!, attribute: .right, multiplier: 1.0, constant: 0.0)
		self.view.addConstraints([heightConstraint, bottomConstraint, leftConstraint, rightConstraint])

		var profileImage : UIImage? = nil
		var profileUsername = "Profile"
		if let current = SnippetsUser.current() {
			profileUsername = "@" + current.userHandle
			profileImage = ImageCache.prefetch(current.pathToUserImage)
		
			if let image = profileImage {
				profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 32.0, height: 32.0)).withRenderingMode(.alwaysOriginal)
			}
		}
		
		let discoverButton = UITabBarItem(title: "Discover", image: UIImage(named: "discover"), tag: 1)
		let timelineButton = UITabBarItem(title: "Timeline", image: UIImage(named: "feed"), tag: 2)
		let profileButton = UITabBarItem(title: profileUsername, image: profileImage, tag: 3)
		
		self.tabBar.delegate = self

		self.tabBar.setItems([discoverButton, timelineButton, profileButton], animated: true)
		self.tabBar.selectedItem = timelineButton

	}
	
	func constructPhoneInterface() {
		self.setupPhoneTabBar()
		self.setupPhoneContentView()
		self.setupPhoneNavigationBar()
		
		// Make sure the tab bar ends up on top...
		self.view.bringSubviewToFront(self.tabBar)
		
		// Update the version label...
		self.menuVersionLabel.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UITabBarDelegate {
	
	func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
		if item.tag == 1 {
			self.onShowDiscover()
		}
		if item.tag == 2 {
			self.onShowTimeline()
		}
		if item.tag == 3 {
			self.onShowProfile()
		}
	}
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var image : UIImage? = nil

		if let img = info[.editedImage] as? UIImage {
			image = img
		}
		else if let img = info[.originalImage] as? UIImage {
			image = img
		}

		
		if let image = image {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Compose", bundle: nil)
			let postViewController = storyBoard.instantiateViewController(withIdentifier: "ComposeViewController") as! ComposeViewController
			postViewController.addImage(image)
			picker.pushViewController(postViewController, animated: true)
		}
		else {
			picker.dismiss(animated: true, completion: nil)
		}
	}
}
