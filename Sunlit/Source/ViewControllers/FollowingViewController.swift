//
//  FollowingViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/4/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class FollowingViewController: UIViewController {

	@IBOutlet var tableView : UITableView!
	
	var following : [SnippetsUser] = []
	var visible = false
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.title = "Following"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(dismissViewController))
	}	
	
	@objc func dismissViewController() {
		self.navigationController?.popViewController(animated: true)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.visible = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.visible = false
	}
	
	func loadPhoto(_ path : String,  _ index : IndexPath) {
		
		// If the photo exists, bail!
		if ImageCache.prefetch(path) != nil {
			return
		}
		
		ImageCache.fetch(self, path) { (image) in
			
			if let _ = image {
				DispatchQueue.main.async {
					if self.visible {
						self.tableView.performBatchUpdates({
							self.tableView.reloadRows(at: [index], with: .fade)
						}, completion: nil)
					}
					else {
						print("Image fetch complete, but ignoring because not visible...")
					}
				}
			}
		}
	}

}

extension FollowingViewController : UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as! ProfileTableViewCell
		let user = self.following[indexPath.row]
		cell.setup(user, indexPath)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let user = self.following[indexPath.row]
		self.loadPhoto(user.avatarURL, indexPath)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.following.count
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let user = self.following[indexPath.row]
		NotificationCenter.default.post(name: .viewUserProfileNotification, object: user)
	}

}
