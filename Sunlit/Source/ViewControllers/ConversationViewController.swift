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
	@IBOutlet var replyingToContainer : UIView!
	@IBOutlet var replyingToButton : UIButton!

	@IBOutlet var replyContainerBottomConstraint : NSLayoutConstraint!
	@IBOutlet var replyTextfieldBottomMarginConstraint: NSLayoutConstraint!

	var posts : [SunlitPost] = []
	var allUsers : Set<String> = []
	var selectedUsers : Set<String> = []
	var sourcePost : SunlitPost? = nil

	var tableViewRefreshControl = UIRefreshControl()

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.setupTable()
		self.setupNavigation()
		self.setupGesture()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.loadConversation()

		self.setupNotifications()
		self.spinner.startAnimating()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		let deviceWithHomeButtonBottomMargin: CGFloat = 8
		let iPhoneWithHomeIndicatorBottomMargin: CGFloat = -2
		let iPadWithHomeIndicatorBottomMargin: CGFloat = 0

		if self.view.safeAreaInsets.bottom > 0 {
			if UIDevice.current.userInterfaceIdiom == .pad {
				self.replyTextfieldBottomMarginConstraint.constant = iPadWithHomeIndicatorBottomMargin
			} else {
				self.replyTextfieldBottomMarginConstraint.constant = iPhoneWithHomeIndicatorBottomMargin
			}
		} else {
			self.replyTextfieldBottomMarginConstraint.constant = deviceWithHomeButtonBottomMargin
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.spinner.stopAnimating()
		NotificationCenter.default.removeObserver(self)

		// need to keep listening for this one
		NotificationCenter.default.addObserver(self, selector: #selector(handleUsernamesChangedNotification(_:)), name: .selectedUsernamesChangedNotification, object: nil)
	}

	@IBAction func back() {
		self.navigationController?.popViewController(animated: true)
	}

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	func setupTable() {
		self.tableViewRefreshControl.addTarget(self, action: #selector(loadConversation), for: .valueChanged)
		self.tableView.addSubview(self.tableViewRefreshControl)
	}
	
	func setupNavigation() {
		self.navigationItem.title = "Conversation"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(back))
	}
	
	func setupGesture() {
		let gesture = UISwipeGestureRecognizer(target: self, action: #selector(back))
		gesture.direction = .right
		self.view.addGestureRecognizer(gesture)
	}
	
	func setupUsernames() {
		if self.allUsers.count == 0 {
			// default to all users in the conversation
			for reply in self.posts {
				if reply.owner.userName != SnippetsUser.current()?.userName {
					self.allUsers.insert(reply.owner.userName)
					self.selectedUsers.insert(reply.owner.userName)
				}
			}
			
			// if no other users, reply to current user
			if self.allUsers.count == 0 {
				if let username = SnippetsUser.current()?.userName {
					self.allUsers.insert(username)
					self.selectedUsers.insert(username)
				}
			}
		}
	}
	
    func buildUsernamesText() -> String {
        var userList = ""
		
		for user in self.selectedUsers {
            userList = userList + "@" + user + " "
        }

        return userList
    }

	func buildReplyText() -> String {
		return self.buildUsernamesText() + self.replyField.text
	}

	@objc func loadConversation() {
		if let post = sourcePost {
			Snippets.Microblog.fetchConversation(post: post) { (error, posts : [SnippetsPost]) in
				
				DispatchQueue.main.async {
					self.posts = [ ]
					
					for post in posts {
						let sunlitPost = SunlitPost.create(post)
						self.posts.insert(sunlitPost, at: 0)
					}

					self.setupUsernames()
					self.tableView.reloadData()
					self.spinner.stopAnimating()
					self.tableViewRefreshControl.endRefreshing()
				}
			}
		}
	}
	
	@IBAction func onShowReplyField() {
		self.replyField.becomeFirstResponder()
	}
	
	@IBAction func onPostReply() {
        
        let replyText = self.buildReplyText()
		_ = Snippets.Microblog.reply(originalPost: self.sourcePost!, content: replyText) { (error) in
			
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

				if self.replyingToContainer.isHidden {
					self.replyingToContainer.alpha = 0.0
					self.replyingToContainer.isHidden = false
					let s = "Replying to " + self.buildUsernamesText()
					self.replyingToButton.setTitle(s, for: .normal)
				}

				UIView.animate(withDuration: 0.25) {
					self.replyTextfieldBottomMarginConstraint.isActive = false
					self.replyContainerBottomConstraint.constant = frame.size.height
					self.postButton.alpha = 1.0
					self.view.layoutIfNeeded()
					self.replyFieldPlaceholder.alpha = 0.0
					self.replyingToContainer.alpha = 1.0
				}
			}
		}
	}

	@objc func keyboardOffScreenNotification(_ notification : Notification) {
				
			UIView.animate(withDuration: 0.25) {
				self.replyContainerBottomConstraint.constant = 0
				self.replyTextfieldBottomMarginConstraint.isActive = true
				//self.tableBottomConstraint.constant = 44
				self.postButton.alpha = 0.0
				self.view.layoutIfNeeded()
				
				self.replyField.text = ""
				
				if self.replyField.text.count <= 0 {
					self.replyFieldPlaceholder.alpha = 1.0
				}

				self.replyingToContainer.alpha = 0.0
			}
	}
	
	@objc func handleAvatarLoadedNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
	}
	
	@objc func handleUsernamesChangedNotification(_ notification: Notification) {
		if let usernames_controller = notification.object as? UsernamesViewController {
			self.selectedUsers = usernames_controller.selectedUsers
			
			if self.selectedUsers.count == 0 {
				// if cleared all users, still reply to current user
				if let username = SnippetsUser.current()?.userName {
					self.allUsers.insert(username)
					self.selectedUsers.insert(username)
				}
			}
			
			let s = "Replying to " + self.buildUsernamesText()
			self.replyingToButton.setTitle(s, for: .normal)
		}
	}
	
	@IBAction func changeReplyingTo(sender: UIButton) {
		let storyboard: UIStoryboard = UIStoryboard(name: "Usernames", bundle: nil)
		if let usernames_controller = storyboard.instantiateInitialViewController() as? UsernamesViewController {
			usernames_controller.allUsers = Array(self.allUsers)
			usernames_controller.selectedUsers = self.selectedUsers
			self.navigationController?.pushViewController(usernames_controller, animated: true)
		}
	}
}

extension ConversationViewController : UITextViewDelegate {
	
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
