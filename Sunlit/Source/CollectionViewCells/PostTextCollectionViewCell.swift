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
		let horizontalInsets = ComposeCollectionViewMetrics.sectionHorizontalInset * 2.0
		let cellWidth = collectionViewWidth - horizontalInsets
		let textInsets = ComposeCollectionViewMetrics.textContainerInsets
		let textWidth = cellWidth
			- textInsets.left
			- textInsets.right
			- (ComposeCollectionViewMetrics.textLineFragmentPadding * 2.0)
		let font = UIFont.preferredFont(forTextStyle: .body)
		let measuredText = text.isEmpty ? " " : text
		let textRect = measuredText.boundingRect(
			with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
			options: [.usesLineFragmentOrigin, .usesFontLeading],
			attributes: [.font: font],
			context: nil
		)
		let textHeight = max(font.lineHeight, ceil(textRect.height))
		let textViewHeight = textHeight + textInsets.top + textInsets.bottom
		let cellHeight = ceil(textViewHeight) + 32.0
		return CGSize(width: cellWidth, height: cellHeight)
	}
}
