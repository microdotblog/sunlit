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
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.title = "Following"
        // Do any additional setup after loading the view.
    }

}

extension FollowingViewController : UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as! ProfileTableViewCell
		let user = self.following[indexPath.row]
		cell.setup(user, indexPath)
		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.following.count
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let user = self.following[indexPath.row]
		NotificationCenter.default.post(name: .viewUserProfileNotification, object: user)
	}

}
