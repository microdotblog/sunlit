//
//  MainTabletViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class MainTabletViewController: UIViewController {

	@IBOutlet var timelineButton : UIButton!
	@IBOutlet var discoverButton : UIButton!
	@IBOutlet var profileButton : UIButton!
	@IBOutlet var settingsButton : UIButton!
	@IBOutlet var composeButton : UIButton!
	@IBOutlet var versionLabel : UILabel!
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
    override func viewDidLoad() {
        super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
		self.setupButtons()
		self.onTimeLine()
		
		self.versionLabel.text = "Version " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
	}
    
	func updateInterfaceForLogin() {
		
		if let user = SnippetsUser.current() {
			
			// Update the user name...
			DispatchQueue.main.async {
				//self.profileButton.setTitle("@" + user.userName, for: .normal)
				self.profileButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
				self.profileButton.setTitle("Profile", for: .normal)
				self.profileButton.centerVertically()
			}
			
			// Go ahead and go get the avatar for the logged in user
			ImageCache.fetch(self, user.avatarURL) { (image) in
				
				if let image = image {
					let	profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysOriginal)
					DispatchQueue.main.async {
						self.profileButton.setImage(profileImage, for: .normal)
						self.profileButton.setImage(profileImage, for: .selected)
						self.profileButton.imageView?.layer.cornerRadius = 12
						self.profileButton.centerVertically()
					}
				}
				else {
					
				}
			}
		}
		else {
			self.profileButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
			self.profileButton.setTitle("Profile", for: .normal)
		}
	}
	
	func setupButtons() {
		var profileImage : UIImage? = UIImage(systemName: "person.crop.circle.fill")
		var profileUsername = "Profile"
		if let current = SnippetsUser.current() {
			//profileUsername = "@" + current.userName
			profileUsername = "Profile"
		
			if let image = ImageCache.prefetch(current.avatarURL) {
				profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 36.0, height: 36.0)).withRenderingMode(.alwaysOriginal)
			}
			else {
				ImageCache.fetch(self, current.avatarURL) { (image) in
					if let image = ImageCache.prefetch(current.avatarURL) {
						let profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysOriginal)
						DispatchQueue.main.async {
							self.profileButton.setImage(profileImage, for: .normal)
							self.profileButton.setImage(profileImage, for: .selected)
							self.profileButton.imageView?.layer.cornerRadius = 12
						}
					}
				}
			}
		}
		self.profileButton.setTitle(profileUsername, for: .normal)
		self.profileButton.setImage(profileImage, for: .normal)
		self.profileButton.setImage(profileImage, for: .selected)
		self.profileButton.imageView?.layer.cornerRadius = 12
		self.profileButton.titleLabel?.lineBreakMode = .byCharWrapping
		self.profileButton.titleLabel?.numberOfLines = 4

		let longpressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onSelectBlogConfiguration))
		self.profileButton.addGestureRecognizer(longpressGesture)
	}
	
	@objc func handleCurrentUserUpdatedNotification() {
		self.updateInterfaceForLogin()
	}
	
	@objc func onSelectBlogConfiguration() {
		Dialog(self).selectBlog()
	}

	func clearButtonStates() {
		self.timelineButton.isSelected = false
		self.discoverButton.isSelected = false
		self.profileButton.isSelected = false
		self.settingsButton.isSelected = false
		self.composeButton.isSelected = false
	}
	

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	@IBAction func onTimeLine() {
		self.clearButtonStates()
		self.timelineButton.isSelected = true
		
		NotificationCenter.default.post(name: .showTimelineNotification, object: nil)
	}
	
	@IBAction func onDiscover() {
		self.clearButtonStates()
		self.discoverButton.isSelected = true

		NotificationCenter.default.post(name: .showDiscoverNotification, object: nil)
	}
	
	@IBAction func onProfile() {
		self.clearButtonStates()
		self.profileButton.isSelected = true

		if let _ = SnippetsUser.current() {
			NotificationCenter.default.post(name: .showCurrentUserProfileNotification, object: nil)
		}
		else {
			self.timelineButton.isSelected = true
			self.profileButton.isSelected = false
			
			NotificationCenter.default.post(name: .showLoginNotification, object: nil)
		}

	}

	@IBAction func onSettings() {
		NotificationCenter.default.post(name: .showSettingsNotification, object: nil)
	}

	@IBAction func onCompose() {
		NotificationCenter.default.post(name: .showComposeNotification, object: nil)
	}

}
