//
//  ConversationViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/11/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import SafariServices
import Snippets

class ConversationViewController: UIViewController {

	@IBOutlet var spinner : UIActivityIndicatorView!
	@IBOutlet var tableView : UITableView!
	@IBOutlet var replyContainer : UIView!
	@IBOutlet var replyField : UITextView!
	@IBOutlet var postButton : UIButton!
	@IBOutlet var replyFieldPlaceholder : UILabel!
	@IBOutlet var replyContainerBottomConstraint : NSLayoutConstraint!

	var posts : [SunlitPost] = []
	var sourcePost : SunlitPost? = nil

	var tableViewRefreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

		self.tableViewRefreshControl.addTarget(self, action: #selector(loadConversation), for: .valueChanged)
		self.tableView.addSubview(self.tableViewRefreshControl)

		self.loadConversation()
		self.navigationItem.title = "Conversation"
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.setupNotifications()
		self.spinner.isHidden = false
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
	}


	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarLoadedNotification(_:)), name: Notification.Name("Avatar Loaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileSelectedNotification), name: NSNotification.Name("Display User Profile"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func loadConversation() {
		if let post = sourcePost {
			Snippets.shared.fetchConversation(post: post) { (error, posts : [SnippetsPost]) in
				self.posts = [ ]
				
				for post in posts {
					let sunlitPost = SunlitPost.create(post)
					self.posts.insert(sunlitPost, at: 0)
				}
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
					self.spinner.isHidden = true
					self.tableViewRefreshControl.endRefreshing()
				}
			}
		}
	}
	
	@IBAction func onShowReplyField() {
		self.replyField.becomeFirstResponder()
	}
	
	@IBAction func onPostReply() {
		Snippets.shared.reply(originalPost: self.sourcePost!, content: self.replyField.text) { (error) in
			
			DispatchQueue.main.async {
				if let err = error {
					Dialog(self).information(err.localizedDescription)
				}
				else {
					self.replyField.text = ""
					self.loadConversation()
				}
			}
		}
		
		self.replyField.resignFirstResponder()
	}
	
	@objc func keyboardOnScreenNotification(_ notification : Notification) {
		
		if let info : [AnyHashable : Any] = notification.userInfo {
			if let value : NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
				let frame = value.cgRectValue
				
				UIView.animate(withDuration: 0.25) {
					self.replyContainerBottomConstraint.constant = frame.size.height - self.view.safeAreaInsets.bottom
					self.postButton.alpha = 1.0
					self.view.layoutIfNeeded()
					self.replyFieldPlaceholder.alpha = 0.0
				}
			}
		}
	}

	@objc func keyboardOffScreenNotification(_ notification : Notification) {
				
			UIView.animate(withDuration: 0.25) {
				self.replyContainerBottomConstraint.constant = self.view.safeAreaInsets.bottom
				self.postButton.alpha = 0.0
				self.view.layoutIfNeeded()
				
				self.replyField.text = ""
				
				if self.replyField.text.count <= 0 {
					self.replyFieldPlaceholder.alpha = 1.0
				}
			}
	}
	
	@objc func handleAvatarLoadedNotification(_ notification: Notification) {
		if let indexPath = notification.object as? IndexPath {
			self.tableView.reloadRows(at: [indexPath], with: .fade)
		}
	}

	@objc func handleUserProfileSelectedNotification(_ notification : Notification) {
		if let post = notification.object as? SunlitPost {
			let storyBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
			let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			profileViewController.user = post.owner
			self.navigationController?.pushViewController(profileViewController, animated: true)
		}
	}
		
}

extension ConversationViewController : UITextViewDelegate {
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		if self.replyField.text.count <= 0 {
			var users = Set<String>()
			for reply in self.posts {
				users.insert(reply.owner.userHandle)
			}
	
			for user in users {
				self.replyField.text = self.replyField.text + "@" + user + " "
			}
		}
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
			self.replyContainer.updateConstraints()
			self.replyContainer.layoutIfNeeded()
		}
		
		return true
	}
	
	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		let safariViewController = SFSafariViewController(url: URL)
		self.present(safariViewController, animated: true, completion: nil)
		return false
	}

}


extension ConversationViewController : UITableViewDelegate, UITableViewDataSource {

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
