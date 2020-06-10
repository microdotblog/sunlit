//
//  SettingsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

	@IBOutlet var versionNumber : UILabel!
	@IBOutlet var microBlogButton : UIButton!
	@IBOutlet var wordPressButton : UIButton!
	@IBOutlet var signOutButton : UIButton!
	
	@IBOutlet var wordPressSettingsView :UIView!
	@IBOutlet var wordPressSettingsViewHeightConstraint : NSLayoutConstraint!
	@IBOutlet var wordPressUserName : UILabel!
	@IBOutlet var wordPressSite : UILabel!
	@IBOutlet var wordPressSignoutButton : UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.versionNumber.text = "Version " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)

		let settingsHeight : CGFloat = self.wordPressButton.isSelected ? 128.0 : 0.0
		self.wordPressSettingsViewHeightConstraint.constant = settingsHeight
	}

	@IBAction func onDismiss() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func onSignout() {

		Dialog(self).question(title: nil, question: "Are you sure you want to log out of your Micro.blog account?", accept: "Log Out", cancel: "Cancel") {
			Settings.logout()
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func onSignoutWordPress() {
		
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
		
		UIView.animate(withDuration: 0.25) {
			self.wordPressSettingsViewHeightConstraint.constant = settingsHeight
			self.view.layoutIfNeeded()
		}
	}
}
