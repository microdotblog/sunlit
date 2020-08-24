//
//  UsernamesViewController.swift
//  Sunlit
//
//  Created by Manton Reece on 8/23/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class UsernamesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet var tableView : UITableView!

	var allUsers: Array<String> = []
	var selectedUsers: Set<String> = []

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.setupNavigation()
		self.setupGesture()
	}
	
	func setupNavigation() {
		self.navigationItem.title = "Usernames"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(back))
	}

	func setupGesture() {
		let gesture = UISwipeGestureRecognizer(target: self, action: #selector(back))
		gesture.direction = .right
		self.view.addGestureRecognizer(gesture)
	}

	@IBAction func back() {
		self.navigationController?.popViewController(animated: true)
	}

	func loadPhoto(_ path : String,  _ index : IndexPath) {
		
		// If the photo exists, bail!
		if ImageCache.prefetch(path) != nil {
			return
		}
		
		ImageCache.fetch(self, path) { (image) in
			
			if let _ = image {
				DispatchQueue.main.async {
					self.tableView.performBatchUpdates({
						self.tableView.reloadRows(at: [index], with: .fade)
					}, completion: nil)
				}
			}
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.allUsers.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "UsernameCheckmarkTableViewCell", for: indexPath) as! UsernameCheckmarkTableViewCell
		
		let username = self.allUsers[indexPath.row]
		cell.usernameField.text = "@" + username

		let url = "https://micro.blog/" + username + "/avatar.jpg"
		if let avatar = ImageCache.prefetch(url) {
			cell.profileImageView.image = avatar
		}

		if self.selectedUsers.contains(username) {
			cell.checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
		}
		else {
			cell.checkmarkImageView.image = UIImage(systemName: "circle")
		}

		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let username = self.allUsers[indexPath.row]
		let url = "https://micro.blog/" + username + "/avatar.jpg"
		self.loadPhoto(url, indexPath)
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let username = self.allUsers[indexPath.row]
		if self.selectedUsers.contains(username) {
			self.selectedUsers.remove(username)
		}
		else {
			self.selectedUsers.insert(username)
		}
		
		tableView.reloadData()
		NotificationCenter.default.post(name: .selectedUsernamesChangedNotification, object: self)
	}

}
