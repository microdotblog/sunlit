//
//  PostTextCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/25/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class PostTextCollectionViewCell: UICollectionViewCell {
	@IBOutlet var postText : UITextView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func size(_ collectionViewWidth : CGFloat, _ text : String) -> CGSize {
		var size = CGSize(width: collectionViewWidth - 24.0, height: 0)
		let rect = text.boundingRect(with: size, options: .usesLineFragmentOrigin , context: nil)
		size.height = rect.size.height
		size.height = size.height + 32.0
		size.width = collectionViewWidth
		if size.height < 60.0 {
			size.height = 60.0
		}
		return size
	}
}
