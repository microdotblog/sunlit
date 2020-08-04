//
//  MentionsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/4/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class MentionsViewController: UIViewController {

	@IBOutlet var spinner : UIActivityIndicatorView!
	@IBOutlet var tableView : UITableView!

	var posts : [SunlitPost] = []

	var tableViewRefreshControl = UIRefreshControl()

	override func viewDidLoad() {
        super.viewDidLoad()
		self.posts = SunlitMentions.shared.allMentions()
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
    }
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		SunlitMentions.shared.allMentionsViewed()
	}
	
	@objc func handleAvatarLoadedNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}

}
    

extension MentionsViewController : UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationTableViewCell", for: indexPath) as! ConversationTableViewCell
		let post = self.posts[indexPath.row]
		cell.setup(post, indexPath)
		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.posts.count
	}

}
