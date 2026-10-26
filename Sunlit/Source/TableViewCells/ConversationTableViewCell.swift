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
	private var configurationGeneration = 0
	private var avatarSource: String?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.avatar.clipsToBounds = true
		self.avatar.layer.cornerRadius = (self.avatar.bounds.size.height - 1) / 2.0

		self.userName.font = UIFont.preferredFont(forTextStyle: .headline)
		self.userHandle.font = UIFont.preferredFont(forTextStyle: .subheadline)
		
		self.addUserProfileTapGesture(self.userName)
		self.addUserProfileTapGesture(self.avatar)
		self.addUserProfileTapGesture(self.userHandle)
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		self.configurationGeneration += 1
		self.post = nil
		self.avatarSource = nil
		self.avatar.image = nil
		self.photosCollectionHeightConstraint?.constant = 0
		self.photosCollectionView?.reloadData()
	}
	
	func setup(_ post : SunlitPost, _ indexPath : IndexPath, isMention: Bool = false) {
		self.configurationGeneration += 1
		self.post = post
		
		self.replyText.attributedText = isMention ? self.mentionText(post.attributedText) : post.attributedText
		self.replyText.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		self.userName.text = post.owner.fullName
		self.userHandle.text = "@" + post.owner.username
		self.userHandle.textColor = isMention ? .secondaryLabel : .label
		self.loadProfilePhoto(post.owner)

		if let date = post.publishedDate {
			self.dateLabel.text = isMention ? date.timestampFormat() : date.friendlyFormat()
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
		self.photosCollectionView?.reloadData()
	}
	
	private func mentionText(_ text: NSAttributedString) -> NSAttributedString {
		let spacedText = NSMutableAttributedString(attributedString: text)
		let lineSpacing = UIFontMetrics(forTextStyle: .body).scaledValue(for: 4, compatibleWith: self.traitCollection)
		text.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: text.length)) { value, range, _ in
			let paragraph = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
			paragraph.lineSpacing = max(paragraph.lineSpacing, lineSpacing)
			spacedText.addAttribute(.paragraphStyle, value: paragraph, range: range)
		}
		return spacedText
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
	
	private func loadProfilePhoto(_ owner: SnippetsUser) {
		let avatarSource = owner.avatarURL
		self.avatarSource = avatarSource
		self.avatar.image = nil
		let generation = self.configurationGeneration
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.avatar.image = avatar
		}
		else {
			ImageCache.fetch(avatarSource) { [weak self] image in
				guard let image = image else { return }
				DispatchQueue.main.async { [weak self] in
					guard let self = self, generation == self.configurationGeneration,
					      self.avatarSource == avatarSource else { return }
					self.avatar.image = image
				}
			}
		}
	}
	
	func loadPostPhotos(_ cell: ConversationPhotoCollectionViewCell, _ indexPath: IndexPath) {
		cell.imageView.image = nil
		cell.imageSource = nil
		guard let post = self.post, indexPath.section == 0,
		      post.images.indices.contains(indexPath.item) else { return }
		let url = post.images[indexPath.item]
		let generation = self.configurationGeneration
		cell.imageSource = url
		if let image = ImageCache.prefetch(url) {
			cell.imageView.image = image
		} else {
			ImageCache.fetch(url) { [weak self, weak cell] image in
				guard let image = image else { return }
				DispatchQueue.main.async { [weak self, weak cell] in
					guard let self = self, let cell = cell,
					      generation == self.configurationGeneration,
					      cell.imageSource == url,
					      self.photosCollectionView?.cellForItem(at: indexPath) === cell,
					      let currentPost = self.post,
					      currentPost.images.indices.contains(indexPath.item),
					      currentPost.images[indexPath.item] == url else { return }
					cell.imageView.image = image
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
		if let post = self.post, indexPath.section == 0, post.images.indices.contains(indexPath.item) {
			let url = post.images[indexPath.item]

			var dictionary : [String : Any] = [:]
			dictionary["imagePath"] = url
			dictionary["post"] = post
		
			NotificationCenter.default.post(name: .viewPostNotification, object: dictionary)
		}
	}
}

