//
//  PostImageCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/25/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class PostImageCollectionViewCell: UICollectionViewCell {
	@IBOutlet var postImage : UIImageView!
	@IBOutlet var widthConstraint : NSLayoutConstraint!

	private let optionsButton = UIButton(type: .custom)

	override func awakeFromNib() {
		super.awakeFromNib()

		self.optionsButton.accessibilityLabel = "Photo options"
		self.optionsButton.showsMenuAsPrimaryAction = true
		self.optionsButton.isUserInteractionEnabled = false
		self.optionsButton.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(self.optionsButton)
		NSLayoutConstraint.activate([
			self.optionsButton.leadingAnchor.constraint(equalTo: self.postImage.leadingAnchor),
			self.optionsButton.trailingAnchor.constraint(equalTo: self.postImage.trailingAnchor),
			self.optionsButton.topAnchor.constraint(equalTo: self.postImage.topAnchor),
			self.optionsButton.bottomAnchor.constraint(equalTo: self.postImage.bottomAnchor)
		])
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		self.optionsButton.menu = nil
	}

	func configureOptionsMenu(_ menu : UIMenu) {
		self.optionsButton.menu = menu
	}

	@available(iOS 17.4, *)
	func showOptionsMenu() {
		self.optionsButton.performPrimaryAction()
	}

	static func size(_ collectionViewWidth : CGFloat) -> CGSize {
		return ComposeCollectionViewMetrics.mediaItemSize(collectionViewWidth)
	}
}
