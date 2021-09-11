//
//  MentionsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/4/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class MentionsViewController: ContentViewController {

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

    override func navbarTitle() -> String {
        return "Mentions"
    }

    @objc override func handleScrollToTopGesture() {
        if self.posts.count > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }

    override func prepareToDisplay() {
        super.prepareToDisplay()

        SunlitMentions.shared.allMentionsViewed()

        self.posts = SunlitMentions.shared.allMentions()
        self.tableView.reloadData()

        SunlitMentions.shared.update {
            self.tableView.reloadData()
        }

		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
			if granted {
				DispatchQueue.main.async {
					UIApplication.shared.registerForRemoteNotifications()
				}
			}
		}
    }

    override func setupNotifications() {
        super.setupNotifications()

        NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserMentionsUpdated), name: .mentionsUpdatedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewConversationNotification(_:)), name: .viewConversationNotification, object: nil)
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

	@objc func handleViewConversationNotification(_ notification : Notification) {
		if let post = notification.object as? SunlitPost {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Conversation", bundle: nil)
			let conversationViewController = storyBoard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
			conversationViewController.sourcePost = post
			self.navigationController?.pushViewController(conversationViewController, animated: true)
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

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 60.0
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 60.0))
		footer.backgroundColor = .clear
		return footer
	}

}


