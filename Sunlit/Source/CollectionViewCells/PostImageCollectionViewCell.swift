//
//  PostImageCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/25/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class PostImageCollectionViewCell: UICollectionViewCell {
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func size(_ collectionViewWidth : CGFloat) -> CGSize {
		var size : CGFloat = 200.0
		if size * 3.0 > collectionViewWidth {
			size = collectionViewWidth / 3.0
		}
		return CGSize(width: size, height: size)
	}
}
