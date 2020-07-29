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

	@IBOutlet var tableView: UITableView!
	
	var menuTitles = [ "Timeline", "Discover", "Profile", "Settings" ]
	var menuIcons = [ "bubble.left.and.bubble.right", "magnifyingglass.circle", "person.crop.circle", "gear" ]

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
    override func viewDidLoad() {
        super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
		self.setupButtons()
		self.onTimeLine()
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(onCollapseMenu))

		if let splitView = self.navigationController?.parent as? UISplitViewController {
			splitView.delegate = self
		}
		
//		self.versionLabel.text = "Version " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
	}

	
	func updateInterfaceForLogin() {
/*
		if let user = SnippetsUser.current() {
			
			// Update the user name...
			DispatchQueue.main.async {
				//self.profileButton.setTitle("@" + user.userName, for: .normal)
//				self.profileButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
//				self.profileButton.setTitle("Profile", for: .normal)
//				self.profileButton.centerVertically()
			}
			
			// Go ahead and go get the avatar for the logged in user
			ImageCache.fetch(self, user.avatarURL) { (image) in
				
				if let image = image {
					let	profileImage = image.uuScaleAndCropToSize(targetSize: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysOriginal)
					DispatchQueue.main.async {
//						self.profileButton.setImage(profileImage, for: .normal)
//						self.profileButton.setImage(profileImage, for: .selected)
//						self.profileButton.imageView?.layer.cornerRadius = 12
//						self.profileButton.centerVertically()
					}
				}
				else {
					
				}
			}
		}
		else {
//			self.profileButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
//			self.profileButton.setTitle("Profile", for: .normal)
		}
*/
	}
	
	func setupButtons() {
/*
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
//							self.profileButton.setImage(profileImage, for: .normal)
//							self.profileButton.setImage(profileImage, for: .selected)
//							self.profileButton.imageView?.layer.cornerRadius = 12
						}
					}
				}
			}
		}
//		self.profileButton.setTitle(profileUsername, for: .normal)
//		self.profileButton.setImage(profileImage, for: .normal)
//		self.profileButton.setImage(profileImage, for: .selected)
//		self.profileButton.imageView?.layer.cornerRadius = 12
//		self.profileButton.titleLabel?.lineBreakMode = .byCharWrapping
//		self.profileButton.titleLabel?.numberOfLines = 4
//
//		let longpressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onSelectBlogConfiguration))
//		self.profileButton.addGestureRecognizer(longpressGesture)
*/
	}
	
	@objc func handleCurrentUserUpdatedNotification() {
		self.updateInterfaceForLogin()
	}
	
	@objc func onSelectBlogConfiguration() {
		Dialog(self).selectBlog()
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	@IBAction func onTimeLine() {
		NotificationCenter.default.post(name: .showTimelineNotification, object: nil)
	}
	
	@IBAction func onDiscover() {
		NotificationCenter.default.post(name: .showDiscoverNotification, object: nil)
	}
	
	@IBAction func onProfile() {
		if let _ = SnippetsUser.current() {
			NotificationCenter.default.post(name: .showCurrentUserProfileNotification, object: nil)
		}
		else {
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

extension MainTabletViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.menuTitles.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "TabletMenuCell", for: indexPath)

		let title = self.menuTitles[indexPath.row]
		var icon = self.menuIcons[indexPath.row]

		if #available(iOS 14, *) {
			if icon == "gear" {
				icon = "gearshape"
			}
		}

		cell.textLabel?.text = title
		cell.imageView?.image = UIImage(systemName: icon)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch indexPath.row {
		case 0:
			self.onTimeLine()
		case 1:
			self.onDiscover()
		case 2:
			self.onProfile()
		case 3:
			self.onSettings()
		default:
			self.onTimeLine()
		}
	}
	
}

extension MainTabletViewController : UISplitViewControllerDelegate {
	

	@objc func onCollapseMenu() {
		if let splitView = self.navigationController?.parent as? UISplitViewController {
			
			NotificationCenter.default.post(name: .splitViewWillCollapseNotification, object: nil)
			
			UIView.animate(withDuration: 0.15) {
				splitView.preferredDisplayMode = .primaryHidden
			}
		}
	}

}
