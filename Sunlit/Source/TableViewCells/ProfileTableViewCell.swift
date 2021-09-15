//
//  ProfileTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/4/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class ProfileTableViewCell: UITableViewCell {

	@IBOutlet var avatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!
	//@IBOutlet var bio : UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()

		self.avatar.clipsToBounds = true
		self.avatar.layer.cornerRadius = (self.avatar.bounds.size.height - 1) / 2.0
		self.avatar.backgroundColor = UIColor.uuColorFromHex("D9D9D9")

		self.userName.font = UIFont.preferredFont(forTextStyle: .headline)
		self.userHandle.font = UIFont.preferredFont(forTextStyle: .subheadline)
	}

	func setup(_ user : SnippetsUser, _ indexPath : IndexPath) {
		self.userName.text = user.fullName
		self.userHandle.text = "@" + user.username
		//self.bio.attributedText = user.attributedTextBio()
		
		self.avatar.image = nil
		
		if let avatar = ImageCache.prefetch(user.avatarURL) {
			self.avatar.image = avatar
		}
	}


}
