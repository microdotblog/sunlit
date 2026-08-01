//
//  PostAddSectionCollectionViewCell.swift
//  Sunlit
//
//  Created by Manton Reece on 5/25/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class PostAddSectionCollectionViewCell: UICollectionViewCell {
	@IBOutlet var titleLabel : UILabel!

	override func awakeFromNib() {
		super.awakeFromNib()
		self.titleLabel.font = .preferredFont(forTextStyle: .subheadline)
	}

	static func size(_ collectionViewWidth : CGFloat) -> CGSize {
		return CGSize(width: collectionViewWidth, height: 74)
	}
	
}
