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
	@IBOutlet var tableBottomConstraint : NSLayoutConstraint!

	var posts : [SunlitPost] = []
	var sourcePost : SunlitPost? = nil

	var tableViewRefreshControl = UIRefreshControl()

	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.tableViewRefreshControl.addTarget(self, action: #selector(loadConversation), for: .valueChanged)
		self.tableView.addSubview(self.tableViewRefreshControl)

		self.loadConversation()

		self.navigationItem.title = "Conversation"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(back))
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.setupNotifications()
		self.spinner.isHidden = false
		self.spinner.startAnimating()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
	}

	@IBAction func back() {
		self.navigationController?.popViewController(animated: true)
	}

	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarLoadedNotification(_:)), name: .refreshCellNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreenNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
    func buildReplyText() -> String {
        var userList = ""
        var users = Set<String>()
        for reply in self.posts {
            users.insert(reply.owner.userName)
        }

        for user in users {
            userList = userList + "@" + user + " "
        }

        return userList + self.replyField.text
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
        
        let replyText = self.buildReplyText()
		Snippets.shared.reply(originalPost: self.sourcePost!, content: replyText) { (error) in
			
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
					self.tableBottomConstraint.constant = frame.size.height + 44
					self.postButton.alpha = 1.0
					self.view.layoutIfNeeded()
					self.replyFieldPlaceholder.alpha = 0.0
				}
			}
		}
	}

	@objc func keyboardOffScreenNotification(_ notification : Notification) {
				
			UIView.animate(withDuration: 0.25) {
				self.tableBottomConstraint.constant = 44
				self.postButton.alpha = 0.0
				self.view.layoutIfNeeded()
				
				self.replyField.text = ""
				
				if self.replyField.text.count <= 0 {
					self.replyFieldPlaceholder.alpha = 1.0
				}
			}
	}
	
	@objc func handleAvatarLoadedNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
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
