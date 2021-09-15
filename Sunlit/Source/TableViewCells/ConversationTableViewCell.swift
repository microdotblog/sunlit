//
//  ConversationTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class ConversationTableViewCell : UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
	
	@IBOutlet var avatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var replyText : UITextView!
	@IBOutlet var photosCollectionView : UICollectionView?
	@IBOutlet var photosCollectionHeightConstraint : NSLayoutConstraint?
	@IBOutlet var dateLabel : UILabel!

	var post : SunlitPost? = nil
	
	override func awakeFromNib() {
		self.avatar.clipsToBounds = true
		self.avatar.layer.cornerRadius = (self.avatar.bounds.size.height - 1) / 2.0

		self.userName.font = UIFont.preferredFont(forTextStyle: .headline)
		self.userHandle.font = UIFont.preferredFont(forTextStyle: .subheadline)
		
		self.addUserProfileTapGesture(self.userName)
		self.addUserProfileTapGesture(self.avatar)
		self.addUserProfileTapGesture(self.userHandle)
	}
	
	func setup(_ post : SunlitPost, _ indexPath : IndexPath) {
		self.post = post
		
		self.replyText.attributedText = post.attributedText
		self.replyText.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		self.userName.text = post.owner.fullName
		self.userHandle.text = "@" + post.owner.userName
		self.loadProfilePhoto(post.owner, indexPath)

		if let date = post.publishedDate {
			self.dateLabel.text = date.friendlyFormat()
		}
		else {
			self.dateLabel.text = ""
		}
		
		if let collection_height_constraint = self.photosCollectionHeightConstraint {
			if post.images.count == 0 {
				collection_height_constraint.constant = 0
			}
			else {
				// 40x40 cells with 4pt padding + 4pt margins around collection view
				collection_height_constraint.constant = 48
			}
		}
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
		NotificationCenter.default.post(name: .viewUserProfileNotification, object: self.post?.owner)
	}
	
	func loadProfilePhoto(_ owner: SnippetsUser, _ indexPath: IndexPath) {
		let avatarSource = owner.avatarURL
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.avatar.image = avatar
		}
		else {
			ImageCache.fetch(avatarSource) { (image) in
				if let _ = image {
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: .refreshCellNotification, object: self, userInfo: [ "index": indexPath ])
					}
				}
			}
		}
	}
	
	func loadPostPhotos(_ cell: ConversationPhotoCollectionViewCell, _ indexPath: IndexPath) {
		if let post = self.post {
			let url = post.images[indexPath.item]
			if let image = ImageCache.prefetch(url) {
				cell.imageView.image = image
			}
			else {
				ImageCache.fetch(url) { image in
					if let _ = image {
						DispatchQueue.main.async {
							self.photosCollectionView?.reloadItems(at: [ indexPath ])
						}
					}
				}
			}
		}
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if let post = self.post {
			return post.images.count
		}
		else {
			return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ConversationPhotoCollectionViewCell", for: indexPath) as! ConversationPhotoCollectionViewCell
		return cell
	}
		
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? ConversationPhotoCollectionViewCell {
			self.loadPostPhotos(cell, indexPath)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let post = self.post {
			let url = post.images[indexPath.item]

			var dictionary : [String : Any] = [:]
			dictionary["imagePath"] = url
			dictionary["post"] = post
		
			NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
		}
	}
}

