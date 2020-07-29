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
	@IBOutlet var versionLabel : UILabel!
	
	var menuTitles = [ "Timeline", "Discover", "Profile", "Settings" ]
	var menuIcons = [ "bubble.left.and.bubble.right", "magnifyingglass.circle", "person.crop.circle", "gear" ]

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.setupNavigationController()

		self.updateInterfaceForUserState()
		self.onTimeLine()

		self.versionLabel.text = "Version " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
	}

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
	}

	func setupNavigationController() {
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(onCollapseMenu))
	}
	
	func updateInterfaceForUserState() {
		if SnippetsUser.current() == nil {
			menuTitles = [ "Login", "Discover" ]
		}
		else {
			menuTitles = [ "Timeline", "Discover", "Profile", "Settings" ]
		}
		
		self.tableView.reloadData()
	}
	
	@objc func handleCurrentUserUpdatedNotification() {
		self.updateInterfaceForUserState()
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
