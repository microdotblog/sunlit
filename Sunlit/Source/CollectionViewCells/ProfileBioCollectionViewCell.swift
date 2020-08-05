//
//  ProfileBioCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

class ProfileBioCollectionViewCell : UICollectionViewCell {
	@IBOutlet var bio : UILabel!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func sizeOf(_ user : SnippetsUser?, collectionViewWidth : CGFloat) -> CGSize {
		
		var size = CGSize(width: collectionViewWidth - 16.0, height: .greatestFiniteMagnitude)
		guard let owner = user else {
			return CGSize(width: collectionViewWidth, height: 0.0)
		}
		
		if owner.bio.count > 0 {
			//DispatchQueue.main.async {
				let text = owner.attributedTextBio()
				let rect = text.boundingRect(with: size, options: .usesLineFragmentOrigin , context: nil)
				size.height = rect.size.height
				size.height = size.height + 16.0
			//}
		}
		
		size.width = collectionViewWidth
		return size
	}

}
