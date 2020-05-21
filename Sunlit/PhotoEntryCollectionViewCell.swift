//
//  PhotoEntryCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class PhotoEntryCollectionViewCell : UICollectionViewCell {
	@IBOutlet var photo : UIImageView!
	@IBOutlet var date : UILabel!

	static func sizeOf(collectionViewWidth : CGFloat) -> CGSize {
		let sections = Int(collectionViewWidth / 200.0)
		var size = CGSize(width: 0, height: 0)
		size.width = (collectionViewWidth / CGFloat(sections)) - (2 * CGFloat(sections))
		size.height = size.width + 48.0
		return size
	}
}
