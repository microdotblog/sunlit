//
//  MainPhoneViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class MainPhoneViewController: UIViewController {

	@IBOutlet var contentView : UIView!
	@IBOutlet var scrollView : UIScrollView!
	@IBOutlet var tabBar : UIView!
	@IBOutlet var timelineButton : UIButton!
	@IBOutlet var discoverButton : UIButton!
	@IBOutlet var profileButton : UIButton!
	

	var discoverViewController : DiscoverViewController!
	var timelineViewController : TimelineViewController!
	var profileViewController : MyProfileViewController!
	var loginViewController : LoginViewController?
	var currentViewController : SnippetsScrollContentProtocol? = nil

	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.setupProfileButton()
		self.loadContentViews()
	}
    
	override func viewDidLayoutSubviews() {
		
		super.viewDidLayoutSubviews()
		
		self.profileButton.centerVertically()
		self.discoverButton.centerVertically()
		self.timelineButton.centerVertically()
		
		//self.stackView.frame = self.tabBar.bounds
		//self.scrollView.frame = self.contentView.bounds
		
		var frame = self.scrollView.frame

		self.timelineViewController.view.frame = frame
		
		frame.origin.x += frame.size.width
		self.discoverViewController.view.frame = frame
		
		frame.origin.x += frame.size.width
		self.profileViewController.view.frame = frame
		
		let contentSize = CGSize(width: frame.size.width * 3.0, height: 0.0)
		self.scrollView.contentSize = contentSize
		
		self.timelineViewController.tableView.reloadData()
		self.discoverViewController.tableView.reloadData()
		self.discoverViewController.collectionView.reloadData()
		self.profileViewController.collectionView.reloadData()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onShowLogin), name: NSNotification.Name("Show Login"), object: nil)
	}
	
	func loadContentViews() {

		let storyboard = UIStoryboard(name: "Content", bundle: nil)
		self.timelineViewController = storyboard.instantiateViewController(identifier: "TimelineViewController")
		self.profileViewController = storyboard.instantiateViewController(identifier: "MyProfileViewController")
		self.discoverViewController = storyboard.instantiateViewController(identifier: "DiscoverViewController")

		self.addChild(self.timelineViewController)
		self.addChild(self.discoverViewController)
		self.addChild(self.profileViewController)

		var frame = self.scrollView.bounds
		self.scrollView.addSubview(self.timelineViewController.view)
		self.timelineViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.addSubview(self.discoverViewController.view)
		self.discoverViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.addSubview(self.profileViewController.view)
		self.profileViewController.view.frame = frame
		frame.origin.x += frame.size.width

		self.scrollView.isUserInteractionEnabled = true
		self.scrollView.contentSize = CGSize(width: frame.origin.x, height: 0)

		self.timelineButton.isSelected = true
		self.currentViewController = self.timelineViewController
		self.timelineViewController.prepareToDisplay()
	}
	
	func setupProfileButton() {
		var profileImage : UIImage? = UIImage(named: "login")
		var profileUsername = "Login"
		if let current = SnippetsUser.current() {
			profileUsername = "@" + current.userHandle
			profileImage = ImageCache.prefetch(current.pathToUserImage)
		
			if let image = profileImage {
				profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 36.0, height: 36.0)).withRenderingMode(.alwaysOriginal)
			}
		}
		self.profileButton.setTitle(profileUsername, for: .normal)
		self.profileButton.setImage(profileImage, for: .normal)

		let longpressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onSelectBlogConfiguration))
		self.profileButton.addGestureRecognizer(longpressGesture)
	}

	func updateInterfaceForLogin() {
		
		if let user = SnippetsUser.current() {
			
			// Update the user name...
			DispatchQueue.main.async {
				self.profileButton.setTitle("@" + user.userHandle, for: .normal)
				self.profileButton.centerVertically()
			}
			
			// Go ahead and go get the avatar for the logged in user
			ImageCache.fetch(user.pathToUserImage) { (image) in
				
				if let image = image {
					let	profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 32.0, height: 32.0)).withRenderingMode(.alwaysOriginal)
					DispatchQueue.main.async {
						self.profileButton.setImage(profileImage, for: .normal)
						self.profileButton.centerVertically()
					}
				}
			}
		}
	}


	@IBAction func onTabBarButtonPressed(_ button : UIButton) {
		if button == self.profileButton {
			if let _ = SnippetsUser.current() {
				self.onShowProfile()
			}
			else {
				self.timelineButton.isSelected = true
				self.profileButton.isSelected = false
				self.onShowLogin()
			}
		}
		if button == self.timelineButton {
			self.onShowTimeline()
		}

		if button == self.discoverButton {
			self.onShowDiscover()
		}
		
	}
	
	@objc func onSelectBlogConfiguration() {
		Dialog(self).selectBlog()
	}
		
	@objc func onShowLogin() {
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
		self.loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")
		self.present(self.loginViewController!, animated: true, completion: nil)
	}
	
	@IBAction func onLogout() {
		
		let alertController = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Logout", style: .default, handler: { (action) in
			Settings.deleteSnippetsToken()
			SnippetsUser.deleteCurrentUser()
			
			Snippets.shared.configure(permanentToken: "", blogUid: nil, mediaEndPoint: nil)
			self.timelineViewController.updateLoggedInStatus()
		}))
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		self.present(alertController, animated: true) {
		}
	}

	
	func onShowProfile() {
		var offset =  self.scrollView.contentOffset
		offset.x = self.scrollView.bounds.size.width * 2.0
		
		self.scrollView.setContentOffset(offset, animated: true)
	}
	
	func onShowTimeline() {
		var offset =  self.scrollView.contentOffset
		offset.x = 0.0
		self.scrollView.setContentOffset(offset, animated: true)
		self.timelineViewController.loadTimeline()
	}
	
	func onShowDiscover() {
		var offset =  self.scrollView.contentOffset
		offset.x = self.scrollView.bounds.size.width * 1.0
		
		self.scrollView.setContentOffset(offset, animated: true)
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
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
						self.timelineViewController.loadTimeline()
					}
					
					Snippets.shared.fetchCurrentUserInfo { (error, updatedUser) in
						
						if let user = updatedUser {
							_ = SnippetsUser.saveAsCurrent(user)
							
							self.updateInterfaceForLogin()
							self.onSelectBlogConfiguration()
						}
					}
				}
			}
		}
	}

}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MainPhoneViewController : UIScrollViewDelegate {
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offset = scrollView.contentOffset.x
		let frameSize = scrollView.bounds.size.width

		self.timelineButton.isSelected = false
		self.profileButton.isSelected = false
		self.discoverButton.isSelected = false
		
		let previousViewController = self.currentViewController
		if offset < (frameSize / 2.0) {
			self.timelineButton.isSelected = true
			self.currentViewController = self.timelineViewController
		}
		else if offset < (frameSize + (frameSize / 2.0)) {
			self.discoverButton.isSelected = true
			self.currentViewController = self.discoverViewController
		}
		else {
			self.profileButton.isSelected = true
			self.currentViewController = self.profileViewController
		}
		
		if !(previousViewController === self.currentViewController) {
			previousViewController?.prepareToHide()
			self.currentViewController?.prepareToDisplay()
		}
		
	}
}

