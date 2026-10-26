//
//  PostTextCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/25/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

protocol PostTextPlaceholder: AnyObject {
	var placeholderText: String { get set }
}

class PostTextCollectionViewCell: UICollectionViewCell {
	@IBOutlet var postText : UITextView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	static func placeholderText(photoCount: Int) -> String {
		return photoCount == 1 ? "Text for this photo…" : "Text for these photos…"
	}

	func updatePlaceholder(photoCount: Int) {
		(self.postText as? PostTextPlaceholder)?.placeholderText = Self.placeholderText(photoCount: photoCount)
	}

	static func size(_ collectionViewWidth : CGFloat, _ text : String, photoCount: Int) -> CGSize {
		let horizontalInsets = ComposeCollectionViewMetrics.sectionHorizontalInset * 2.0
		let cellWidth = collectionViewWidth - horizontalInsets
		let textInsets = ComposeCollectionViewMetrics.textContainerInsets
		let textWidth = cellWidth
			- textInsets.left
			- textInsets.right
			- (ComposeCollectionViewMetrics.textLineFragmentPadding * 2.0)
		let font = UIFont.preferredFont(forTextStyle: .body)
		let measuredText = text.isEmpty ? Self.placeholderText(photoCount: photoCount) : text
		let textRect = measuredText.boundingRect(
			with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
			options: [.usesLineFragmentOrigin, .usesFontLeading],
			attributes: [.font: font],
			context: nil
		)
		let textHeight = max(font.lineHeight, ceil(textRect.height))
		let textViewHeight = textHeight + textInsets.top + textInsets.bottom
		let cellHeight = ceil(textViewHeight)
			+ ComposeCollectionViewMetrics.textCellTopInset
			+ ComposeCollectionViewMetrics.textCellBottomInset
		return CGSize(width: cellWidth, height: cellHeight)
	}
}
