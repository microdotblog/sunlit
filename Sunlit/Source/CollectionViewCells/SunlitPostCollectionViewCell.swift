//
//  SunlitPostCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/28/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SunlitPostCollectionViewCell: UICollectionViewCell {
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var timeStampLabel : UILabel!
	@IBOutlet var videoPlayIndicator : UIImageView!

	var representedImagePath: String?
}
