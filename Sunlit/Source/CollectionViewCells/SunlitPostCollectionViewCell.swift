//
//  SunlitPostCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/28/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import AVKit

class SunlitPostCollectionViewCell: UICollectionViewCell {
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var timeStampLabel : UILabel!
	@IBOutlet var videoPlayIndicator : UIImageView!

	var representedImagePath: String?
	private var player: AVQueuePlayer?
	private var playerLayer: AVPlayerLayer?
	private var playerLooper: AVPlayerLooper?
	private var timeObserver: Any?

	override func prepareForReuse() {
		super.prepareForReuse()
		self.resetVideoPlayer()
		self.representedImagePath = nil
	}

	deinit {
		self.resetVideoPlayer()
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.playerLayer?.frame = self.contentView.bounds
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		if self.window == nil {
			self.pauseVideoPlayback()
		}
	}

	func resetVideoPlayer() {
		if let timeObserver = self.timeObserver {
			self.player?.removeTimeObserver(timeObserver)
		}
		self.timeObserver = nil
		self.player?.pause()
		self.playerLooper?.disableLooping()
		self.playerLooper = nil
		self.playerLayer?.removeFromSuperlayer()
		self.playerLayer = nil
		self.player = nil
	}

	func configureVideoPlayer(url: URL) {
		self.resetVideoPlayer()
		self.timeStampLabel.text = "00:00"
		self.timeStampLabel.alpha = 0.0
		self.timeStampLabel.isHidden = false
		self.postImage.contentMode = .scaleAspectFit

		let item = AVPlayerItem(url: url)
		let player = AVQueuePlayer(playerItem: item)
		let layer = AVPlayerLayer(player: player)
		layer.videoGravity = .resizeAspect
		layer.frame = self.contentView.bounds
		layer.isHidden = true
		self.contentView.layer.addSublayer(layer)
		self.contentView.bringSubviewToFront(self.timeStampLabel)
		self.player = player
		self.playerLayer = layer
		self.playerLooper = AVPlayerLooper(player: player, templateItem: item)

		self.timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: .main) { [weak self, weak player] time in
			guard let self = self, let player = player else { return }
			let elapsed = CMTimeGetSeconds(time)
			guard elapsed.isFinite else { return }
			let seconds = Int(elapsed)
			self.timeStampLabel.text = String(format: "%02d:%02d", seconds / 60, seconds % 60)
			if player.rate > 0.0 && self.timeStampLabel.alpha == 0.0 {
				UIView.animate(withDuration: 0.15) {
					self.timeStampLabel.alpha = 1.0
				}
			}
		}
	}

	func pauseVideoPlayback() {
		self.player?.pause()
	}

	func toggleVideoPlayback() {
		guard let player = self.player else { return }
		if player.rate == 0.0 {
			self.playerLayer?.isHidden = false
			player.play()
		}
		else {
			player.pause()
		}
	}
}
