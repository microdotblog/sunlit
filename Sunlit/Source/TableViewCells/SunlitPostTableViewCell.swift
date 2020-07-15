//
//  SunlitPostTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/19/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import AVKit
import Snippets


class SunlitPostTableViewCell : UITableViewCell {

	@IBOutlet var pageViewIndicator : UIPageControl!
	@IBOutlet var collectionView : UICollectionView!
	@IBOutlet var textView : UITextView!
	@IBOutlet var dateLabel : UILabel!
	@IBOutlet var userAvatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var collectionViewHeightConstraint : NSLayoutConstraint!
	@IBOutlet var collectionViewWidthConstraint : NSLayoutConstraint!
	@IBOutlet var replyContainer : UIView!
	@IBOutlet var replyField : UITextView!
	@IBOutlet var replyButton : UIButton!
	@IBOutlet var postButton : UIButton!
	@IBOutlet var conversationButton : UIButton!
	@IBOutlet var conversationHeightConstraint : NSLayoutConstraint!
	
	var post : SunlitPost!
	
	// Video playback interface...
	var player : AVQueuePlayer? = nil
	var playerLayer : AVPlayerLayer? = nil
	var playerLooper : AVPlayerLooper? = nil


	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	static func photoHeight(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		let width : CGFloat = parentWidth
		let maxHeight : CGFloat = 600.0
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
			let conversationHeight = NSString(string: "Conversation").size(withAttributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1)]).height
			height = height + conversationHeight
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
		
		self.userName.font = UIFont.preferredFont(forTextStyle: .caption1)
		self.userHandle.font = UIFont.preferredFont(forTextStyle: .caption2)

		// Configure the user avatar
		self.userAvatar.clipsToBounds = true
		self.userAvatar.layer.cornerRadius = (self.userAvatar.bounds.size.height - 1) / 2.0
		
		// Add the user profile tap gestures where appropriate...
		self.addUserProfileTapGesture(self.userName)
		self.addUserProfileTapGesture(self.userAvatar)
		self.addUserProfileTapGesture(self.userHandle)
	}
	
	func setup(_ index: Int, _ post : SunlitPost, parentWidth : CGFloat) {
		
		self.post = post
		
		self.replyContainer.layer.borderWidth = 0.0

		self.conversationButton.isHidden = !self.post.hasConversation
		
//		let conversationFont = UIFont.preferredFont(forTextStyle: .caption1)
//		let conversationPadding: CGFloat = 15
//		self.conversationButton.titleLabel?.font = conversationFont
//		let conversationHeight = NSString(string: "Conversation").size(withAttributes: [NSAttributedString.Key.font : conversationFont]).height + conversationPadding
//		self.conversationHeightConstraint.constant = self.post.hasConversation ? conversationHeight : 0.0
		
		// Update the text objects
		self.textView.attributedText = post.text
		self.userHandle.text = "@" + post.owner.userName
		self.userName.text = post.owner.fullName
		
		if let date = post.publishedDate {
			self.dateLabel.text = date.friendlyFormat()
		}
		else {
			self.dateLabel.text = ""
		}

		self.pageViewIndicator.hidesForSinglePage = true
		self.pageViewIndicator.numberOfPages = self.post.images.count

		self.setupAvatar()

		// Configure the photo sizes...
		let height = self.setupPhotoAspectRatio(post, parentWidth: parentWidth)
		self.configureCollectionView(CGSize(width: self.bounds.size.width, height: height))
		self.collectionView.reloadData() // Needed to force the collection view to reload itself...
	}
	
	func setupPhotoAspectRatio(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		let height = SunlitPostTableViewCell.photoHeight(post, parentWidth: parentWidth)
		self.collectionViewWidthConstraint.constant = parentWidth
		self.collectionViewHeightConstraint.constant = height
		return height
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	@IBAction func onReply() {
		Snippets.shared.reply(originalPost: self.post, content: self.replyField.text) { (error) in
			NotificationCenter.default.post(name: .notifyReplyPostedNotification, object: error)
		}
		
		self.textView.resignFirstResponder()
	}
	
	@IBAction func onViewConversation() {
		NotificationCenter.default.post(name: .viewConversationNotification, object: self.post)
	}
	
	@IBAction func onActivateReply() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreen(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreen(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleEmojiSelectedNotification(_:)), name: .emojiSelectedNotification, object: nil)
		self.replyContainer.layer.borderWidth = 0.5;

		self.replyField.isHidden = false
		self.replyButton.isHidden = true
		self.postButton.isHidden = false
		self.conversationButton.isHidden = true

		self.replyField.alpha = 0.0
		self.replyButton.alpha = 1.0
		self.postButton.alpha = 0.0

		UIView.animate(withDuration: 0.35) {
			self.replyField.alpha = 1.0
			self.replyButton.alpha = 0.0
			self.postButton.alpha = 1.0
			self.replyContainer.backgroundColor = UIColor(named: "color_reply_background")
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
				let cellOffset : CGFloat = self.frame.origin.y
				let textBoxOffset = self.replyContainer.frame.origin.y + self.replyContainer.frame.size.height
				let tableViewLocation = cellOffset + textBoxOffset
				let dictionary : [String : Any] = [ "keyboardOffset" : rawFrame, "tableViewLocation" : tableViewLocation]
				
				NotificationCenter.default.post(name: .scrollTableViewNotification, object: dictionary)
			}
		}
	}
	
	@objc func keyboardOffScreen(_ notification : Notification) {
			
		self.replyContainer.layer.borderWidth = 0.0

		self.replyField.isHidden = true
		self.replyButton.isHidden = false
		self.postButton.isHidden = true
		self.conversationButton.isHidden = !self.post.hasConversation

		UIView.animate(withDuration: 0.35) {
			self.replyField.alpha = 0.0;
			self.replyButton.alpha = 1.0;
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
		NotificationCenter.default.post(name: .viewUserProfileNotification, object: self.post.owner)
	}
	
	@objc func handleEmojiSelectedNotification(_ notification : Notification) {
		if let emoji = notification.object as? String {
			self.replyField.text = self.replyField.text + emoji
		}
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func setupAvatar() {
		
		self.userAvatar.image = nil
		let avatarSource = self.post.owner.avatarURL
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.userAvatar.image = avatar
		}
	}
}

extension SunlitPostTableViewCell : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	
	func configureCollectionView(_ size: CGSize) {
		
		if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.itemSize = size
			//layout.estimatedItemSize = size
			layout.headerReferenceSize = CGSize(width: 0.0, height: 0.0)
			layout.footerReferenceSize = CGSize(width: 0.0, height: 0.0)
			layout.sectionInset = UIEdgeInsets()
			layout.minimumInteritemSpacing = 0.0
			layout.minimumLineSpacing = 0.0
		}
	}
	
	func configureVideoPlayer(_ cell : SunlitPostCollectionViewCell, _ indexPath : IndexPath) {
	
		cell.timeStampLabel.text = "00:00:00"
		cell.timeStampLabel.alpha = 0.0
		cell.timeStampLabel.isHidden = false

		if let url = URL(string: self.post.videos[indexPath.item]) {
			let playerItem = AVPlayerItem(url: url)
			let player = AVQueuePlayer(playerItem: playerItem)
			let playerLayer = AVPlayerLayer(player: player)
			cell.contentView.layer.addSublayer(playerLayer)
			cell.contentView.bringSubviewToFront(cell.timeStampLabel)

			playerLayer.frame = self.collectionView.bounds
			playerLayer.isHidden = true

			self.player = player
			self.playerLayer = playerLayer
			self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)

			player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: DispatchQueue.main) { (time : CMTime) in
				let rawTime = Double(CMTimeGetSeconds(time))
				var seconds = Int(CMTimeGetSeconds(time))
				let milliseconds = Int((rawTime - Double(seconds)) * 100)
				let minutes = (seconds / 60)
				seconds = seconds - (60 * minutes)
				let timeString = String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
				cell.timeStampLabel.text = timeString
				
				// Animate in the timestamp label
				if player.rate > 0.0 && cell.timeStampLabel.alpha == 0.0 {
					UIView.animate(withDuration: 0.15) {
						cell.timeStampLabel.alpha = 1.0
					}
				}
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.post.images.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let imagePath = self.post.images[indexPath.item]
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SunlitPostCollectionViewCell", for: indexPath) as! SunlitPostCollectionViewCell
		cell.videoPlayIndicator.isHidden = true
		cell.timeStampLabel.isHidden = true
		cell.postImage.image = nil
		cell.timeStampLabel.isHidden = true

		if let image = ImageCache.prefetch(imagePath) {
			cell.postImage.image = image
		}

		let hasVideo = (self.post.videos.count > 0)
		cell.videoPlayIndicator.isHidden = !hasVideo
		if hasVideo {
			self.configureVideoPlayer(cell, indexPath)
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		self.pageViewIndicator.currentPage = indexPath.item
	}
	
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		
		// See if we have a valid player...
		if let player = self.player,
			let playerLayer = self.playerLayer {
				player.pause()
				playerLayer.removeFromSuperlayer()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		if self.post.videos.count > 0 {

			if let player = self.player,
				let playerLayer = self.playerLayer {
				if player.rate == 0.0 {
					//playerLayer.frame = collectionView.bounds
					playerLayer.isHidden = false
					player.play()
				}
				else {
					player.pause()
				}
			}
			
		}
		else {
			let imagePath = self.post.images[indexPath.item]
			var dictionary : [String : Any] = [:]
			dictionary["imagePath"] = imagePath
			dictionary["post"] = self.post
			
			NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return collectionView.bounds.size
	}
}
