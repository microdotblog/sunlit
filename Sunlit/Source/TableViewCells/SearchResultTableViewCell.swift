//
//  SearchResultTableViewCell.swift
//  Sunlit
//
//  Created by Manton Reece on 8/22/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class SearchResultTableViewCell: UITableViewCell {

	@IBOutlet var avatar : UIImageView!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userHandle : UILabel!

	override func awakeFromNib() {
		super.awakeFromNib()

		self.avatar.clipsToBounds = true
		self.avatar.layer.cornerRadius = (self.avatar.bounds.size.height - 1) / 2.0

		self.userName.font = UIFont.preferredFont(forTextStyle: .headline)
		self.userHandle.font = UIFont.preferredFont(forTextStyle: .subheadline)
	}

	func setup(_ user : SnippetsUser, _ indexPath : IndexPath) {
		self.userName.text = user.fullName
		self.userHandle.text = "@" + user.userName
		
		self.avatar.image = nil
		
		if let avatar = ImageCache.prefetch(user.avatarURL) {
			self.avatar.image = avatar
		}
	}

}
