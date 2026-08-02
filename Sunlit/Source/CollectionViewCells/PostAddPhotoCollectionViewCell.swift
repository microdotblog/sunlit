//
//  PostAddPhotoCollectionViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/25/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class PostAddPhotoCollectionViewCell: UICollectionViewCell {
	@IBOutlet var widthConstraint : NSLayoutConstraint!
	@IBOutlet var addIcon : UIImageView!

	private let symbolFillView = UIView()

	override func awakeFromNib() {
		super.awakeFromNib()

		self.addIcon.backgroundColor = .clear
		self.addIcon.tintColor = .systemGray
		self.symbolFillView.backgroundColor = .systemGray6
		self.symbolFillView.layer.cornerRadius = 9.0
		self.symbolFillView.isUserInteractionEnabled = false
		self.symbolFillView.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.insertSubview(self.symbolFillView, belowSubview: self.addIcon)
		NSLayoutConstraint.activate([
			self.symbolFillView.centerXAnchor.constraint(equalTo: self.addIcon.centerXAnchor),
			self.symbolFillView.centerYAnchor.constraint(equalTo: self.addIcon.centerYAnchor),
			self.symbolFillView.widthAnchor.constraint(equalToConstant: 18.0),
			self.symbolFillView.heightAnchor.constraint(equalTo: self.symbolFillView.widthAnchor)
		])
	}

	static func size(_ collectionViewWidth : CGFloat) -> CGSize {
		return ComposeCollectionViewMetrics.mediaItemSize(collectionViewWidth)
	}

}
