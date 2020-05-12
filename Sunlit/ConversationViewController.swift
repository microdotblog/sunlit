//
//  ConversationViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/11/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

	@IBOutlet var tableView : UITableView!
	@IBOutlet var replyContainer : UIView!
	@IBOutlet var replyField : UITextView!
	@IBOutlet var postButton : UIButton!
	@IBOutlet var replyFieldPlaceholder : UILabel!
	@IBOutlet var replyContainerBottomConstraint : NSLayoutConstraint!

	var posts : [SunlitPost] = []
	var sourcePost : SunlitPost? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.loadConversation()
		self.setupNotifications()
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarLoadedNotification(_:)), name: Notification.Name("Avatar Loaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleUserProfileSelectedNotification), name: NSNotification.Name("Display User Profile"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	func loadConversation() {
		if let post = sourcePost {
			Snippets.shared.fetchConversation(post: post.source) { (error, posts : [SnippetsPost]) in
				self.posts = [ ]
				
				for post in posts {
					let sunlitPost = SunlitPost.create(post)
					self.posts.insert(sunlitPost, at: 0)
				}
				
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			}
		}
	}
	
	@IBAction func onShowReplyField() {
		self.replyField.becomeFirstResponder()
	}
	
	@IBAction func onPostReply() {
		Snippets.shared.reply(originalPost: self.sourcePost!.source, content: self.replyField.text) { (error) in
			if let err = error {
				Dialog.information(err.localizedDescription, self)
			}
			else {
				self.replyField.text = ""
				self.loadConversation()
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
			let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
			let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
			profileViewController.user = post.owner
			self.navigationController?.pushViewController(profileViewController, animated: true)
		}
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
			self.replyContainer.updateConstraints()
			self.replyContainer.layoutIfNeeded()
		}
		
		return true
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.posts.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationTableViewCell", for: indexPath) as! ConversationTableViewCell
		let post = self.posts[indexPath.row]
		cell.setup(post, indexPath)
		return cell
	}

}

class ConversationTableViewCell : UITableViewCell {
	@IBOutlet var avatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var replyText : UITextView!
	
	var post : SunlitPost? = nil
	
	override func awakeFromNib() {
		self.avatar.clipsToBounds = true
		self.avatar.layer.cornerRadius = (self.avatar.bounds.size.height - 1) / 2.0

		self.addUserProfileTapGesture(self.userName)
		self.addUserProfileTapGesture(self.avatar)
		self.addUserProfileTapGesture(self.userHandle)
	}
	
	func setup(_ post : SunlitPost, _ indexPath : IndexPath) {
		self.post = post
		
		self.replyText.attributedText = post.text
		self.userName.text = post.owner.fullName
		self.userHandle.text = "@" + post.owner.userHandle
		self.loadPhotos(post.owner, indexPath)
	}
	
	func addUserProfileTapGesture(_ view : UIView) {
		view.isUserInteractionEnabled = true

		for gesture in view.gestureRecognizers ?? [] {
			view.removeGestureRecognizer(gesture)
		}

		let gesture = UITapGestureRecognizer(target: self, action: #selector(handleUserTappedGesture))
		view.addGestureRecognizer(gesture)
	}
	
	@objc func handleUserTappedGesture() {
		NotificationCenter.default.post(name: NSNotification.Name("Display User Profile"), object: self.post)
	}
	
	func loadPhotos(_ owner : SnippetsUser, _ indexPath : IndexPath) {
		let avatarSource = owner.pathToUserImage
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.avatar.image = avatar
		}
		else {
			ImageCache.fetch(avatarSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: NSNotification.Name("Avatar Loaded"), object: indexPath)
					}
				}
			}
		}
	}
}
