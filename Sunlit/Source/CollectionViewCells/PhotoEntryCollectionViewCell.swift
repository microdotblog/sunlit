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
		var sections = Int(collectionViewWidth / 160.0)
		if sections < 2 {
			sections = 2
		}
		        
		let width = (collectionViewWidth / CGFloat(sections)) - 8.0
        
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let constrainedSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let dateString = "Date"
        var height : CGFloat = width + dateString.boundingRect(with: constrainedSize, options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics], attributes: [NSAttributedString.Key.font: font], context: nil).height
        height = height + 14.0
		return CGSize(width: width, height: height)
	}
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.date.font = UIFont.preferredFont(forTextStyle: .footnote)
    }
}
