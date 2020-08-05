//
//  ProfileHeaderCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class ProfileHeaderCollectionViewCell : UICollectionViewCell {
	@IBOutlet var avatar : UIImageView!
	@IBOutlet var followButton : UIButton!
	@IBOutlet var fullName : UILabel!
	@IBOutlet var userHandle : UILabel!
	@IBOutlet var blogAddress : UIButton!
    @IBOutlet var busyIndicator : UIActivityIndicatorView!

	@IBOutlet var mentionsLabel : UILabel!
	@IBOutlet var mentionsContainer : UIView!
	@IBOutlet var followingLabel : UILabel!
	@IBOutlet var followingContainer : UIView!
	
	static func sizeOf(_ owner : SnippetsUser?, collectionViewWidth : CGFloat) -> CGSize {
		return CGSize(width: collectionViewWidth, height: 120.0)
	}
	
	func configureMentions() {
		self.mentionsLabel.textColor = .white
		self.mentionsContainer.isHidden = false
		
		let newCount = SunlitMentions.shared.newMentionCount()
		if newCount > 0 {
			self.mentionsContainer.backgroundColor = .red
			self.mentionsLabel.text = "\(newCount) new mentions"
		}
		else {
			let count = SunlitMentions.shared.allMentions().count
			self.mentionsContainer.backgroundColor = .black
			self.mentionsLabel.text = "\(count) mentions"
		}
		
		if UIDevice.current.userInterfaceIdiom != .phone {
			self.mentionsContainer.isHidden = true
		}
	}
	
	func configureFollowing(count : Int, complete : Bool) {
		self.followingContainer.isHidden = false
		self.followingLabel.text = "Following \(count)"
		if !complete {
			self.followingLabel.text = "Updating..."
		}
	}
	
	@IBAction func openBlogAddress() {
		if let s = blogAddress.title(for: .normal) {
			if let url = URL(string: s) {
				UIApplication.shared.open(url)
			}
		}
	}
	
	@IBAction func showMentions() {
		NotificationCenter.default.post(name: .showMentionsNotification, object: nil, userInfo: nil)
	}
	
	@IBAction func showFollowing() {
		NotificationCenter.default.post(name: .followingButtonClickedNotification, object: nil, userInfo: nil)
	}
}
