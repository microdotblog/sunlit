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
		return photoHeight(post, parentWidth: parentWidth) + 40.0 + 16.0
	}

	override func awakeFromNib() {
		super.awakeFromNib()

		self.userName.font = UIFont.preferredFont(forTextStyle: .caption1)
		self.userHandle.font = UIFont.preferredFont(forTextStyle: .caption2)

		// Configure the user avatar
		self.userAvatar.clipsToBounds = true
		self.userAvatar.layer.cornerRadius = (self.userAvatar.bounds.size.height - 1) / 2.0
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
		if let avatar = ImageCache.prefetch(avatarSource) {
			self.userAvatar.image = avatar
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
        if let avatar = ImageCache.prefetch(avatarSource)
        {
            self.userAvatar.image = avatar
        }

        
        for i in 0...self.post.images.count - 1
        {
            let imagePath = self.post.images[i]
            if let image = ImageCache.prefetch(imagePath)
            {
                if let cell = self.collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? SunlitPostCollectionViewCell
                {
                    cell.postImage.image = image
                }
            }
            else if blurHash.count > 0
            {
                if let image = ImageCache.prefetch(blurHash)
                {
                    let cell = self.collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as! SunlitPostCollectionViewCell
                    cell.postImage.image = image
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

		if let image = ImageCache.prefetch(imagePath) {
			cell.postImage.image = image
		}
		else if blurHash.count > 0 {
			if let image = ImageCache.prefetch(blurHash) {
				cell.postImage.image = image
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
