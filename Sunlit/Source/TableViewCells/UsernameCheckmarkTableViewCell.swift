//
//  UsernameCheckmarkTableViewCell.swift
//  Sunlit
//
//  Created by Manton Reece on 8/23/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class UsernameCheckmarkTableViewCell: UITableViewCell {

	@IBOutlet var checkmarkImageView : UIImageView!
	@IBOutlet var profileImageView : UIImageView!
	@IBOutlet var usernameField : UILabel!

	override func awakeFromNib() {
		super.awakeFromNib()

		self.profileImageView.clipsToBounds = true
		self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.size.height / 2.0
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

}
