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
	@IBOutlet var followingCount : UILabel!
	@IBOutlet var postCount : UILabel!
    @IBOutlet var busyIndicator : UIActivityIndicatorView!
	@IBOutlet var mentionsLabel : UILabel!
	@IBOutlet var mentionsContainer : UIView!
	
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
}
