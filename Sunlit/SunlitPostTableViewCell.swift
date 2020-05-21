//
//  SunlitPostTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/19/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SunlitPostTableViewCell : UITableViewCell {
	
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var textView : UITextView!
	@IBOutlet var dateLabel : UILabel!
	@IBOutlet var userAvatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var heightConstraint : NSLayoutConstraint!
	@IBOutlet var replyContainer : UIView!
	@IBOutlet var replyField : UITextView!
	@IBOutlet var replyButton : UIButton!
	@IBOutlet var replyIconButton : UIButton!
	@IBOutlet var postButton : UIButton!
	@IBOutlet var conversationButton : UIButton!
	@IBOutlet var conversationHeightConstraint : NSLayoutConstraint!
	
	var post : SunlitPost!
	

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	
	static func photoHeight(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		let width : CGFloat = parentWidth
		let maxHeight : CGFloat = 400.0
		var height : CGFloat = width * CGFloat(post.aspectRatio)
		if height > maxHeight {
			height = maxHeight
		}
		
		return height
	}
	
	static func height(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		var height : CGFloat = 72.0
		height = height + SunlitPostTableViewCell.photoHeight(post, parentWidth: parentWidth)
		height = height + 8.0
		height = height + 16.0 // Timestamp
		height = height + 8.0
		height = height + SunlitPostTableViewCell.textHeight(post, parentWidth: parentWidth)
		height = height + 44.0
		
		if post.hasConversation {
			height = height + 44.0
		}
		
		height = height + 32.0 // Reply container
		height = height + 16.0
	
		return height
	}
	
	static func textHeight(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		let size = CGSize(width: parentWidth - 34.0, height: .greatestFiniteMagnitude)
		let text = post.text
		let rect = text.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics] , context: nil)
		return ceil(rect.size.height)
	}
	

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	
	override func awakeFromNib() {
		super.awakeFromNib()

		self.replyContainer.layer.cornerRadius = 18.0
		self.replyContainer.layer.borderColor = UIColor.lightGray.cgColor
		self.replyContainer.layer.borderWidth = 0.0

		// Configure the user avatar
		self.userAvatar.clipsToBounds = true
		self.userAvatar.layer.cornerRadius = (self.userAvatar.bounds.size.height - 1) / 2.0
		
		// Add the user profile tap gestures where appropriate...
		self.addUserProfileTapGesture(self.userName)
		self.addUserProfileTapGesture(self.userAvatar)
		self.addUserProfileTapGesture(self.userHandle)
	}
	

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
	
	func setup(_ index: Int, _ post : SunlitPost, parentWidth : CGFloat) {
		
		self.post = post
		
		self.replyContainer.layer.borderWidth = 0.0

		self.conversationButton.isHidden = !self.post.hasConversation
		self.conversationHeightConstraint.constant = self.post.hasConversation ? 44.0 : 0.0
		
		// Update the text objects
		self.textView.attributedText = post.text
		self.userHandle.text = "@" + post.owner.userHandle
		self.userName.text = post.owner.fullName
		
		if let date = post.publishedDate {
			self.dateLabel.text = date.friendlyFormat()
		}
		
		// Configure the photo sizes...
		self.setupPhotoAspectRatio(post, parentWidth: parentWidth)
		
		// Kick off the photo loading...
		self.loadPhotos(post, index)
	}
	
	func setupPhotoAspectRatio(_ post : SunlitPost, parentWidth : CGFloat) {
		self.heightConstraint.constant = SunlitPostTableViewCell.photoHeight(post, parentWidth: parentWidth)
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@IBAction func onReply() {
		Snippets.shared.reply(originalPost: self.post, content: self.replyField.text) { (error) in
			NotificationCenter.default.post(name: NSNotification.Name("Reply Response"), object: error)
		}
		
		self.textView.resignFirstResponder()
	}
	
	@IBAction func onViewConversation() {
		NotificationCenter.default.post(name: NSNotification.Name("View Conversation"), object: self.post)
	}
	
	@IBAction func onActivateReply() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreen(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreen(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleEmojiSelectedNotification(_:)), name: NSNotification.Name("Emoji Selected"), object: nil)
		self.replyContainer.layer.borderWidth = 0.5;

		self.replyField.isHidden = false
		self.replyButton.isHidden = true
		self.replyIconButton.isHidden = true
		self.postButton.isHidden = false

		self.replyField.alpha = 0.0
		self.replyButton.alpha = 1.0
		self.replyIconButton.alpha = 1.0
		self.postButton.alpha = 0.0

		UIView.animate(withDuration: 0.35) {
			self.replyField.alpha = 1.0
			self.replyButton.alpha = 0.0
			self.replyIconButton.alpha = 0.0
			self.postButton.alpha = 1.0
			self.replyContainer.backgroundColor = UIColor.white
		}
		
		self.replyField.becomeFirstResponder()
		
		if replyField.text.count <= 0 {
			for name in self.post.mentionedUsernames {
				replyField.text = replyField.text + name + " "
			}
		}
	}
	
	@objc func keyboardOnScreen(_ notification : Notification) {
		if let info : [AnyHashable : Any] = notification.userInfo {
			if let value : NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
				let rawFrame = value.cgRectValue
				
				var safeArea : CGFloat = 0.0
				safeArea = safeArea + UIApplication.shared.windows[0].safeAreaInsets.bottom
				let textBoxOffset = self.replyContainer.frame.origin.y + self.replyContainer.frame.size.height - 10.5
				let cellOffset : CGFloat = self.frame.origin.y
				let keyboardSize : CGFloat = rawFrame.size.height
				let offset = cellOffset + textBoxOffset - keyboardSize - safeArea
				
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Keyboard Appear"), object: offset)
			}
			
		}
	}
	
	@objc func keyboardOffScreen(_ notification : Notification) {
			
		self.replyContainer.layer.borderWidth = 0.0

		self.replyField.isHidden = true
		self.replyButton.isHidden = false
		self.replyIconButton.isHidden = false
		self.postButton.isHidden = true

		UIView.animate(withDuration: 0.35) {
			self.replyField.alpha = 0.0;
			self.replyButton.alpha = 1.0;
			self.replyIconButton.alpha = 1.0;
			self.postButton.alpha = 0.0;
			self.replyContainer.backgroundColor = UIColor.clear
		}
		
		NotificationCenter.default.removeObserver(self)
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func addUserProfileTapGesture(_ view : UIView) {
		view.isUserInteractionEnabled = true

		for gesture in view.gestureRecognizers ?? [] {
			view.removeGestureRecognizer(gesture)
		}

		let gesture = UITapGestureRecognizer(target: self, action: #selector(handleUserTappedGesture))
		view.addGestureRecognizer(gesture)
	}
	
	@objc func handleUserTappedGesture() {
		NotificationCenter.default.post(name: NSNotification.Name("Display User Profile"), object: self.post.owner)
	}
	
	@objc func handleEmojiSelectedNotification(_ notification : Notification) {
		if let emoji = notification.object as? String {
			self.replyField.text = self.replyField.text + emoji
		}
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func loadPhotos(_ post : SunlitPost, _ index : Int) {
		
		self.postImage.image = nil //UIImage(named: "welcome_waves")
		self.userAvatar.image = nil
		
		let imageSource = post.images[0]
		if let image = ImageCache.prefetch(imageSource) {
			self.postImage.image = image
		}
		
		let avatarSource = post.owner.pathToUserImage
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.userAvatar.image = avatar
		}
	}
}
