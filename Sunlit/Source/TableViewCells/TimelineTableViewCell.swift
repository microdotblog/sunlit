//
//  TimelineTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/17/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit
import AVKit
import Snippets

class TimelineTableViewCell : UITableViewCell {

	@IBOutlet var userAvatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var pageViewIndicator : UIPageControl!
	@IBOutlet var pageViewIndicatorContainer : UIView!
	@IBOutlet var collectionView : UICollectionView!
	@IBOutlet var collectionViewHeightConstraint : NSLayoutConstraint!
	@IBOutlet var collectionViewWidthConstraint : NSLayoutConstraint!

	var post : SunlitPost!
	private let identityBubble = UIView()


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

		return ceil(height)
	}

	static func height(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		return photoHeight(post, parentWidth: parentWidth) + 5.0
	}

	override func awakeFromNib() {
		super.awakeFromNib()

		self.collectionView.showsHorizontalScrollIndicator = false
		self.contentView.constraints.first(where: { constraint in
			constraint.firstItem as? UIView === self.contentView &&
			constraint.firstAttribute == .bottom &&
			constraint.secondItem as? UIView === self.pageViewIndicatorContainer &&
			constraint.secondAttribute == .bottom
		})?.constant = 10.0
		self.setupIdentityBubble()
	}

	private func setupIdentityBubble() {
		let headerView = self.userAvatar.superview
		let headerConstraints = headerView?.constraints.filter { constraint in
			constraint.firstItem as? UIView === self.userAvatar ||
			constraint.secondItem as? UIView === self.userAvatar ||
			constraint.firstItem as? UIView === self.userHandle ||
			constraint.secondItem as? UIView === self.userHandle
		} ?? []
		NSLayoutConstraint.deactivate(headerConstraints)
		let avatarSizeConstraints = self.userAvatar.constraints.filter { constraint in
			constraint.firstAttribute == .width || constraint.firstAttribute == .height
		}
		NSLayoutConstraint.deactivate(avatarSizeConstraints)

		self.userAvatar.removeFromSuperview()
		self.userHandle.removeFromSuperview()
		headerView?.constraints.first(where: { $0.firstAttribute == .height })?.constant = 0.0
		headerView?.isHidden = true

		self.identityBubble.isUserInteractionEnabled = false
		self.identityBubble.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
		self.identityBubble.clipsToBounds = true
		self.identityBubble.layer.cornerRadius = 20.0
		self.identityBubble.layer.cornerCurve = .continuous
		self.identityBubble.translatesAutoresizingMaskIntoConstraints = false

		self.userAvatar.contentMode = .scaleAspectFill
		self.userAvatar.clipsToBounds = true
		self.userAvatar.layer.cornerRadius = 14.0
		self.userAvatar.translatesAutoresizingMaskIntoConstraints = false

		self.userHandle.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
		self.userHandle.textColor = .label
		self.userHandle.numberOfLines = 1
		self.userHandle.translatesAutoresizingMaskIntoConstraints = false

		self.contentView.addSubview(self.identityBubble)
		self.identityBubble.addSubview(self.userAvatar)
		self.identityBubble.addSubview(self.userHandle)

		NSLayoutConstraint.activate([
			self.identityBubble.leadingAnchor.constraint(equalTo: self.collectionView.leadingAnchor, constant: 8.0),
			self.identityBubble.topAnchor.constraint(equalTo: self.collectionView.topAnchor, constant: 8.0),

			self.userAvatar.leadingAnchor.constraint(equalTo: self.identityBubble.leadingAnchor, constant: 6.0),
			self.userAvatar.topAnchor.constraint(equalTo: self.identityBubble.topAnchor, constant: 6.0),
			self.userAvatar.bottomAnchor.constraint(equalTo: self.identityBubble.bottomAnchor, constant: -6.0),
			self.userAvatar.widthAnchor.constraint(equalToConstant: 28.0),
			self.userAvatar.heightAnchor.constraint(equalToConstant: 28.0),

			self.userHandle.leadingAnchor.constraint(equalTo: self.userAvatar.trailingAnchor, constant: 6.0),
			self.userHandle.trailingAnchor.constraint(equalTo: self.identityBubble.trailingAnchor, constant: -12.0),
			self.userHandle.centerYAnchor.constraint(equalTo: self.identityBubble.centerYAnchor)
		])
	}

	func setup(_ index: Int, _ post : SunlitPost, parentWidth : CGFloat) {

		for cell in self.collectionView.visibleCells {
			(cell as? SunlitPostCollectionViewCell)?.resetVideoPlayer()
		}
		self.post = post

		self.userHandle.text = "@" + post.owner.username
		self.userName.text = post.owner.fullName

		// Configure the photo sizes...
		let height = self.setupPhotoAspectRatio(post, parentWidth: parentWidth)
		self.configureCollectionView(CGSize(width: self.bounds.size.width, height: height))
		self.collectionView.reloadData() // Needed to force the collection view to reload itself...

		self.pageViewIndicator.hidesForSinglePage = true
		self.pageViewIndicator.numberOfPages = self.post.images.count
		self.pageViewIndicatorContainer.isHidden = self.post.images.count < 2

		self.userAvatar.image = nil
	}

	func setupPhotoAspectRatio(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		let height = TimelineTableViewCell.photoHeight(post, parentWidth: parentWidth)
		self.collectionViewWidthConstraint.constant = parentWidth
		self.collectionViewHeightConstraint.constant = height
		return height
	}

	func loadImages() {
		if let firstImage = self.post.images.first {
			ImageCache.loadForDisplay(firstImage)
		}

		let source = self.post.owner.avatarURL
		ImageCache.loadForDisplay(source) { [weak self] image in
			guard let self, self.post?.owner.avatarURL == source else { return }
			self.userAvatar.image = image
		}
	}

}


extension TimelineTableViewCell : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

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

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.post.images.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let imagePath = self.post.images[indexPath.item]
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SunlitPostCollectionViewCell", for: indexPath) as! SunlitPostCollectionViewCell
		cell.resetVideoPlayer()
		let isVideo = self.post.videos[indexPath.item] != nil
		cell.postImage.contentMode = isVideo ? .scaleAspectFit : .scaleAspectFill
		cell.videoPlayIndicator.isHidden = !isVideo
		cell.timeStampLabel.isHidden = true
		cell.postImage.image = nil
		cell.representedImagePath = imagePath

		ImageCache.loadForDisplay(imagePath) { [weak cell] image in
			guard let cell, cell.representedImagePath == imagePath else { return }
			cell.postImage.image = image
		}

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		self.pageViewIndicator.currentPage = indexPath.item
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		(cell as? SunlitPostCollectionViewCell)?.pauseVideoPlayback()
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		if let source = self.post.videos[indexPath.item] {
			if let url = URL(string: source),
			   let cell = collectionView.cellForItem(at: indexPath) as? SunlitPostCollectionViewCell {
				cell.toggleVideoPlayback(url: url)
			}
		} else {
			NotificationCenter.default.post(name: .viewConversationNotification, object: self.post)
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return collectionView.bounds.size
	}
}
