//
//  PhotoEntryCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/20/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class PhotoEntryCollectionViewSpacerCell : UICollectionViewCell {

}

class PhotoEntryCollectionViewCell : UICollectionViewCell {
	@IBOutlet var photo : UIImageView!
	@IBOutlet var date : UILabel!
    @IBOutlet var selectionIndicator : UIImageView? = nil
	@IBOutlet var selectionBackgroundView : UIView? = nil
	private var photoPath: String?

	override func prepareForReuse() {
		super.prepareForReuse()
		self.photoPath = nil
	}

	func loadPhoto(_ path: String?) {
		self.photoPath = path
		self.photo.image = nil
		guard let path else { return }
		ImageCache.loadForDisplay(path) { [weak self] image in
			guard let self, self.photoPath == path else { return }
			self.photo.image = image
		}
	}

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

    override var isSelected: Bool {
        didSet {
            if let selectionIndicator = self.selectionIndicator {
                selectionIndicator.isHidden = !isSelected
            }
			if let selectionBackgroundView = self.selectionBackgroundView {
				selectionBackgroundView.isHidden = !isSelected
			}
        }
    }
}
