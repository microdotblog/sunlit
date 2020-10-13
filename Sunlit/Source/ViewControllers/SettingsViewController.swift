//
//  SettingsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

	@IBOutlet var signOutButton : UIButton!
    @IBOutlet var tableView : UITableView!
    @IBOutlet var settingsLabel : UILabel!
	
    var tableData : [BlogSettings] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
	
		self.setupNavigation()
		self.setupNotifications()
		let versionString : String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
		self.settingsLabel.text = versionString
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        self.tableData = BlogSettings.publishedBlogs()
        self.tableView.reloadData()
        self.updateSelection()
	}
	
	func setupNavigation() {
		self.navigationItem.title = "Settings"
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Credits", style: .plain, target: self, action: #selector(onViewCredits))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(onDismiss))
	}
	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(finishedExternalConfigNotification), name: .finishedExternalConfigNotification, object: nil)
	}
		
	@objc func finishedExternalConfigNotification(_ notification: Notification) {
        self.tableData = BlogSettings.publishedBlogs()
        self.tableView.reloadData()
        self.updateSelection()
	}
    
    func updateSelection() {
        
        let selectedName = BlogSettings.blogForPublishing().blogName
        
        var index = 0
        for settings in self.tableData {
            if settings.blogName == selectedName {
                self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            }
            index = index + 1
        }
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
	
	@IBAction func onAddBlog() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let blogConfigurationViewController = storyBoard.instantiateViewController(withIdentifier: "ExternalBlogConfigurationViewController")
        self.navigationController?.pushViewController(blogConfigurationViewController, animated: true)
	}
	
	@IBAction @objc func onViewCredits() {
		let storyboard: UIStoryboard = UIStoryboard(name: "About", bundle: nil)
		let about_controller = storyboard.instantiateViewController(withIdentifier: "AboutViewController")
		self.navigationController?.pushViewController(about_controller, animated: true)
	}
	

}

extension SettingsViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= self.tableData.count {
            return tableView.dequeueReusableCell(withIdentifier: "BlogSelectionAddNewCell")!
        }
        
        let blogInfo = self.tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlogSelectionTableViewCell", for: indexPath) as! BlogSelectionTableViewCell
        cell.blogTitle.text = blogInfo.blogName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row >= self.tableData.count {
            self.onAddBlog()
            self.updateSelection()
        }
        else {
            let blogInfo = self.tableData[indexPath.row]
            BlogSettings.setBlogForPublishing(blogInfo)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.tableData.count > 1
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let blogInfo = self.tableData[indexPath.row]
        Dialog(self).question(title: nil, question: "Are you sure you want to delete the settings for \(blogInfo.blogName)?", accept: "Delete", cancel: "Cancel") {
            BlogSettings.deletePublishedBlog(blogInfo)

            self.tableData = BlogSettings.publishedBlogs()
            self.tableView.reloadData()
            self.updateSelection()
        }
    }
    
}
