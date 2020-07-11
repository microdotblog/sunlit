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
		
		self.navigationItem.title = "Settings"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Credits", style: .plain, target: self, action: #selector(onViewCredits))
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
	
	func updateWordpressSettings() {
		
		self.wordPressUserName.text = PublishingConfiguration.current.getBlogName()
		self.wordPressSite.text = PublishingConfiguration.current.getBlogAddress()
			
		if PublishingConfiguration.current.hasConfigurationForExternal() {
			self.wordPressSignoutButton.setTitle("Log Out", for: .normal)
		}
		else {
			self.wordPressUserName.text = "Not signed in"
			self.wordPressSite.text = ""
			self.wordPressSignoutButton.setTitle("Log In", for: .normal)
		}
		
		var appName = PublishingConfiguration.current.getExternalBlogAppName()
		if appName.count <= 0 {
			appName = "External Weblog"
		}
		self.wordPressAppTitle.text = appName
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

		Dialog(self).question(title: nil, question: "Are you sure you want to log out of your Micro.blog account?", accept: "Log Out", cancel: "Cancel") {
			Settings.logout()

			NotificationCenter.default.post(name: .currentUserUpdatedNotification, object: nil)
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func onSignoutWordPress() {
		if PublishingConfiguration.current.hasConfigurationForExternal() {
			Dialog(self).question(title: nil, question: "Are you sure you want to log out of your WordPress account?", accept: "Log Out", cancel: "Cancel") {
			
				PublishingConfiguration.deleteXMLRPCBlogSettings()
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
			self.wordPressLogin()
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
