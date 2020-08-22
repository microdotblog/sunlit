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
	
    var contentViewController : UIViewController!
    
	var menuTitles = [ "Timeline", "Mentions", "Discover", "Profile", "Settings" ]
	var menuIcons = [ "bubble.left.and.bubble.right", "at", "magnifyingglass.circle", "person.crop.circle",  "gear" ]

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupNotifications()
		self.setupNavigationController()

		self.updateInterfaceForUserState()
        
        if !self.splitViewController!.isCollapsed {
            self.onTimeLine()
        }
        
		self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)

		self.versionLabel.text = "Version " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
	}

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleMentionsUpdatedNotification), name: .mentionsUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentUserUpdatedNotification), name: .currentUserUpdatedNotification, object: nil)
	}

	func setupNavigationController() {
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(onCollapseMenu))
	}
	
	func updateInterfaceForUserState() {
		if SnippetsUser.current() == nil {
			menuTitles = [ "Timeline", "Discover" ]
		}
		else {
			menuTitles = [ "Timeline", "Mentions", "Discover", "Profile", "Settings"]
		}
		
		self.tableView.reloadData()
	}
	
	@objc func handleCurrentUserUpdatedNotification() {
		self.updateInterfaceForUserState()
	}
	
	@objc func handleMentionsUpdatedNotification() {
		//let selectedIndexPath = self.tableView.indexPathForSelectedRow
		//self.tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
		//self.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
	}
	
	@objc func onSelectBlogConfiguration() {
		Dialog(self).selectBlog()
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	@IBAction func onTimeLine() {
        if self.splitViewController!.isCollapsed {
            self.navigationController?.pushViewController(self.contentViewController, animated: true)
        }
		NotificationCenter.default.post(name: .showTimelineNotification, object: nil)
	}

    @IBAction func onMentions() {
        if self.splitViewController!.isCollapsed {
            self.navigationController?.pushViewController(self.contentViewController, animated: true)
        }

        NotificationCenter.default.post(name: .showMentionsNotification, object: nil)
    }

	@IBAction func onDiscover() {
        if self.splitViewController!.isCollapsed {
            self.navigationController?.pushViewController(self.contentViewController, animated: true)
        }
		NotificationCenter.default.post(name: .showDiscoverNotification, object: nil)
	}
	
	@IBAction func onProfile() {
        if self.splitViewController!.isCollapsed {
            self.navigationController?.pushViewController(self.contentViewController, animated: true)
        }

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
		let cell = tableView.dequeueReusableCell(withIdentifier: "TabletMenuTableViewCell", for: indexPath) as! TabletMenuTableViewCell

		let title = self.menuTitles[indexPath.row]
		var icon = self.menuIcons[indexPath.row]

		if #available(iOS 14, *) {
			if icon == "gear" {
				icon = "gearshape"
			}
		}

		cell.titleLabel.text = title
		
		if icon == "bubble.left.and.bubble.right" {
			// make this smaller since it is so wide
			let config = UIImage.SymbolConfiguration(scale: .small)
			cell.iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
		}
		else {
			cell.iconImageView.image = UIImage(systemName: icon)
		}
		
		cell.alertContainer.isHidden = true
		
		// Special case code for mentions...
		if indexPath.row == 1 {
//			cell.alertContainer.isHidden = true
//
//			let newCount = SunlitMentions.shared.newMentionCount()
//			if newCount > 0 {
//				cell.alertContainer.isHidden = false
//				cell.alertContainer.backgroundColor = .red
//				cell.alertLabel.text = "\(newCount)"
//			}
		}
		
			return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch indexPath.row {
		case 0:
			self.onTimeLine()
		case 1:
			if SnippetsUser.current() != nil {
				self.onMentions()
			}
			else {
				self.onDiscover()
			}
		case 2:
			self.onDiscover()
		case 3:
			self.onProfile()
		case 4:
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
