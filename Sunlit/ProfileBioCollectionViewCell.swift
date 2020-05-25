//
//  ProfileBioCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ProfileBioCollectionViewCell : UICollectionViewCell {
	@IBOutlet var bio : UILabel!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func sizeOf(_ owner : SnippetsUser, collectionViewWidth : CGFloat) -> CGSize {
		var size = CGSize(width: collectionViewWidth - 16.0, height: 0)
		
		if owner.bio.count > 0 {
			let text = owner.attributedTextBio()
			let rect = text.boundingRect(with: size, options: .usesLineFragmentOrigin , context: nil)
			size.height = rect.size.height
			size.height = size.height + 16.0
		}
		
		size.width = collectionViewWidth
		return size
	}

}
