//
//  SettingsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

	@IBOutlet var microBlogButton : UIButton!
	@IBOutlet var wordPressButton : UIButton!
	@IBOutlet var signOutButton : UIButton!
	
	@IBOutlet var wordPressSettingsView :UIView!
	@IBOutlet var wordPressSettingsViewHeightConstraint : NSLayoutConstraint!
	@IBOutlet var wordPressUserName : UILabel!
	@IBOutlet var wordPressSite : UILabel!
	@IBOutlet var wordPressSignoutButton : UIButton!
	@IBOutlet var wordPressAppTitle : UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
	
		self.setupNavigation()
		self.setupNotifications()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.wordPressButton.isSelected = Settings.usesExternalBlog()
		self.microBlogButton.isSelected = !Settings.usesExternalBlog()
		
		self.updateWordpressSettings()
		let settingsHeight : CGFloat = self.wordPressButton.isSelected ? 128.0 : 0.0
		self.wordPressSettingsViewHeightConstraint.constant = settingsHeight

		self.updateWordpressSettings()
	}
	
	func setupNavigation() {
		self.navigationItem.title = "Settings"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Credits", style: .plain, target: self, action: #selector(onViewCredits))
	}
	
	func setupNotifications() {
	}
	
	func updateWordpressSettings() {
		let blog_name = PublishingConfiguration.current.getBlogName()
		let blog_address = PublishingConfiguration.current.getBlogAddress()
		self.wordPressUserName.text = blog_name
		if blog_address != blog_name {
			self.wordPressSite.text = blog_address
		}
		else {
			self.wordPressSite.text = ""
		}
			
		if PublishingConfiguration.current.hasConfigurationForExternal() {
			self.wordPressSignoutButton.setTitle("Sign Out", for: .normal)
		}
		else {
			self.wordPressUserName.text = ""
			self.wordPressSite.text = ""
			self.wordPressSignoutButton.setTitle("Sign In", for: .normal)
		}
		
		var appName = PublishingConfiguration.current.getExternalBlogAppName()
		if appName.count <= 0 {
			appName = "External Weblog"
		}
		self.wordPressAppTitle.text = appName

		if self.wordPressButton.isSelected {
			self.wordPressAppTitle.isHidden = false
			self.wordPressSignoutButton.isHidden = false
			self.wordPressUserName.isHidden = false
			self.wordPressSite.isHidden = false
		}
		else {
			self.wordPressAppTitle.isHidden = true
			self.wordPressSignoutButton.isHidden = true
			self.wordPressUserName.isHidden = true
			self.wordPressSite.isHidden = true
		}
	}
	
	func wordPressLogin() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
		let blogConfigurationViewController = storyBoard.instantiateViewController(withIdentifier: "ExternalBlogConfigurationViewController")
		self.navigationController?.pushViewController(blogConfigurationViewController, animated: true)
	}

	@IBAction func onDismiss() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func onSignout() {

		Dialog(self).question(title: nil, question: "Are you sure you want to sign out of your Micro.blog account?", accept: "Sign Out", cancel: "Cancel") {
			Settings.logout()

			NotificationCenter.default.post(name: .currentUserUpdatedNotification, object: nil)
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func onSignoutWordPress() {
		if PublishingConfiguration.current.hasConfigurationForExternal() {
			Dialog(self).question(title: nil, question: "Are you sure you want to sign out of your external blog?", accept: "Sign Out", cancel: "Cancel") {
			
				PublishingConfiguration.deleteXMLRPCBlogSettings()
				PublishingConfiguration.deleteMicropubSettings()
				self.onSelectPostType(self.microBlogButton)
			}
		}
		else {
			self.wordPressLogin()
		}
	}
	
	@IBAction @objc func onViewCredits() {
		let storyBoard: UIStoryboard = UIStoryboard(name: "About", bundle: nil)
		let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "AboutViewController")
		self.present(newPostViewController, animated: true, completion: nil)
	}
	
	@IBAction func onSelectPostType(_ button : UIButton) {
		
		self.microBlogButton.isSelected = false
		self.wordPressButton.isSelected = false
		button.isSelected = true
		
		let settingsHeight : CGFloat = self.wordPressButton.isSelected ? 128.0 : 0.0

		// Three configurations here to manage...
		if self.wordPressButton.isSelected && !PublishingConfiguration.current.hasConfigurationForExternal() {
//			self.wordPressLogin()
		}
		else if self.wordPressButton.isSelected {
			Settings.useExternalBlog(true)
		}
		else {
			Settings.useExternalBlog(false)
		}
		
		self.updateWordpressSettings()
		
		UIView.animate(withDuration: 0.25) {
			self.wordPressSettingsViewHeightConstraint.constant = settingsHeight
			self.view.layoutIfNeeded()
		}
		
		
	}
}
