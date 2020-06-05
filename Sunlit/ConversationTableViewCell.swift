//
//  ConversationTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

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

