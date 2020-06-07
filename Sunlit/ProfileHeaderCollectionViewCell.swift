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
	@IBOutlet var blogAddress : UITextView!
	@IBOutlet var followingCount : UILabel!
	@IBOutlet var postCount : UILabel!
	@IBOutlet var widthConstraint : NSLayoutConstraint!
	
	static func sizeOf(_ owner : SnippetsUser, collectionViewWidth : CGFloat) -> CGSize {
		return CGSize(width: collectionViewWidth, height: 120.0)
/*
		var size = CGSize(width: collectionViewWidth, height: 0)
		
		size.height = size.height + 24
		size.height = size.height + 60
		size.height = size.height + 8
		
		if owner.pathToWebSite.count > 0 {
			size.height = size.height + 16
			size.height = size.height + 32
		}
		
		return size
*/
	}
}
