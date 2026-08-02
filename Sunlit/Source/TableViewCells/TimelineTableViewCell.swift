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
import BlurHash

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
	private var avatarSource: String?
	private let identityBubble = UIView()

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

	private func setPreparedAvatar(_ image: UIImage, source: String) {
		self.avatarSource = source

		image.prepareForDisplay { [weak self] preparedImage in
			DispatchQueue.main.async {
				guard let self = self, self.avatarSource == source else { return }
				self.userAvatar.image = preparedImage ?? image
			}
		}
	}

	private func setPreparedPostImage(_ image: UIImage, source: String, in cell: SunlitPostCollectionViewCell) {
		cell.representedImagePath = source

		image.prepareForDisplay { [weak cell] preparedImage in
			DispatchQueue.main.async {
				guard let cell = cell, cell.representedImagePath == source else { return }
				cell.postImage.image = preparedImage ?? image
			}
		}
	}

	func setup(_ index: Int, _ post : SunlitPost, parentWidth : CGFloat) {

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

		self.setupAvatar()
	}

	func setupPhotoAspectRatio(_ post : SunlitPost, parentWidth : CGFloat) -> CGFloat {
		let height = TimelineTableViewCell.photoHeight(post, parentWidth: parentWidth)
		self.collectionViewWidthConstraint.constant = parentWidth
		self.collectionViewHeightConstraint.constant = height
		return height
	}

	func setupAvatar() {
		self.userAvatar.image = nil
		let avatarSource = self.post.owner.avatarURL
		self.avatarSource = avatarSource
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.setPreparedAvatar(avatar, source: avatarSource)
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

	func configureVideoPlayer(_ cell : SunlitPostCollectionViewCell, _ indexPath : IndexPath) {

		cell.timeStampLabel.text = "00:00"
		cell.timeStampLabel.alpha = 0.0
		cell.timeStampLabel.isHidden = false
		cell.postImage.contentMode = .scaleAspectFill

		let thumbnail = self.post.images[indexPath.item]
		if let videoPath = self.post.videos[thumbnail],
		   let url = URL(string: videoPath) {

			cell.postImage.contentMode = .scaleAspectFit
			
			let playerItem = AVPlayerItem(url: url)
			let player = AVQueuePlayer(playerItem: playerItem)
			let playerLayer = AVPlayerLayer(player: player)
			playerLayer.videoGravity = .resizeAspect
			cell.contentView.layer.addSublayer(playerLayer)
			cell.contentView.bringSubviewToFront(cell.timeStampLabel)

			playerLayer.frame = CGRect(origin: .zero, size: self.collectionView.bounds.size)
			playerLayer.isHidden = true

			self.player = player
			self.playerLayer = playerLayer
			self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)

			player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: DispatchQueue.main) { (time : CMTime) in
				var seconds = Int(CMTimeGetSeconds(time))
				let minutes = (seconds / 60)
				seconds = seconds - (60 * minutes)
				let timeString = String(format: "%02d:%02d", minutes, seconds)
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

    func reloadImages()
    {
        let defaultPhoto = self.post.defaultPhoto
        let blurHash : String = defaultPhoto["blurhash"] as? String ?? ""

        let avatarSource = self.post.owner.avatarURL
		self.avatarSource = avatarSource
        if let avatar = ImageCache.prefetch(avatarSource)
        {
            self.setPreparedAvatar(avatar, source: avatarSource)
        }

        
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            if indexPath.item >= self.post.images.count {
                continue
            }

            let imagePath = self.post.images[indexPath.item]
            if let image = ImageCache.prefetch(imagePath) {
                if let cell = self.collectionView.cellForItem(at: indexPath) as? SunlitPostCollectionViewCell {
                    self.setPreparedPostImage(image, source: imagePath, in: cell)
                }
            }
            else if blurHash.count > 0 {
                if let image = ImageCache.prefetch(blurHash) {
                    if let cell = self.collectionView.cellForItem(at: indexPath) as? SunlitPostCollectionViewCell {
                        self.setPreparedPostImage(image, source: imagePath, in: cell)
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
		let defaultPhoto = self.post.defaultPhoto
		let blurHash : String = defaultPhoto["blurhash"] as? String ?? ""
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SunlitPostCollectionViewCell", for: indexPath) as! SunlitPostCollectionViewCell
		cell.videoPlayIndicator.isHidden = true
		cell.timeStampLabel.isHidden = true
		cell.postImage.image = nil
		cell.timeStampLabel.isHidden = true
		cell.representedImagePath = imagePath

		if let image = ImageCache.prefetch(imagePath) {
			self.setPreparedPostImage(image, source: imagePath, in: cell)
		}
		else if blurHash.count > 0 {
			if let image = ImageCache.prefetch(blurHash) {
				self.setPreparedPostImage(image, source: imagePath, in: cell)
			}
		}

		let thumbnail = self.post.images[indexPath.item]
		let hasVideo = self.post.videos[thumbnail] != nil
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
		if let cell = cell as? SunlitPostCollectionViewCell,
		   let player = self.player,
		   let playerLayer = self.playerLayer,
		   cell.contentView.layer == playerLayer.superlayer {
			player.pause()
			playerLayer.removeFromSuperlayer()
		}
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		let thumbnail = self.post.images[indexPath.item]
		if self.post.videos[thumbnail] != nil {

			if let player = self.player,
			   let playerLayer = self.playerLayer {
				if player.rate == 0.0 {
					playerLayer.isHidden = false
					playerLayer.frame = CGRect(origin: .zero, size: collectionView.bounds.size)
					player.play()
				}
				else {
					player.pause()
				}
			}

		}
		else {
			NotificationCenter.default.post(name: .viewConversationNotification, object: self.post)
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return collectionView.bounds.size
	}
}
