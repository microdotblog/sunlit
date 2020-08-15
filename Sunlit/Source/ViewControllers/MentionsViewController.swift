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
    }
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	@objc func handleAvatarLoadedNotification(_ notification: Notification) {
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
	
	@objc func handleUserMentionsUpdated() {
		DispatchQueue.main.async {
			self.posts = SunlitMentions.shared.allMentions()
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
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let post = self.posts[indexPath.row]
		let storyBoard: UIStoryboard = UIStoryboard(name: "Conversation", bundle: nil)
		let conversationViewController = storyBoard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
		conversationViewController.sourcePost = post
		self.navigationController?.pushViewController(conversationViewController, animated: true)
	}

}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
MARK: -
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

extension MentionsViewController : SnippetsScrollContentProtocol {
	func prepareToDisplay() {
		self.navigationController?.navigationBar.topItem?.title = "Mentions"
		self.navigationController?.navigationBar.topItem?.titleView = nil
		
		SunlitMentions.shared.allMentionsViewed()

		self.posts = SunlitMentions.shared.allMentions()
		self.tableView.reloadData()
		
		SunlitMentions.shared.update {
		}

		NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserMentionsUpdated), name: .mentionsUpdatedNotification, object: nil)
	}
	
	func prepareToHide() {
		NotificationCenter.default.removeObserver(self)
	}

}
