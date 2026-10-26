//
//  SectionTextView.swift
//  Sunlit
//
//  Created by Manton Reece on 7/22/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SectionTextView: UITextView, PostTextPlaceholder {
	private let placeholderLabel = UILabel()
	var placeholderText = PostTextCollectionViewCell.placeholderText(photoCount: 0) {
		didSet {
			self.placeholderLabel.text = self.placeholderText
			self.setNeedsLayout()
		}
	}

	override var text: String! {
		didSet { self.updatePlaceholder() }
	}

	override var attributedText: NSAttributedString! {
		didSet { self.updatePlaceholder() }
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.textContainerInset = ComposeCollectionViewMetrics.textContainerInsets
		self.textContainer.lineFragmentPadding = ComposeCollectionViewMetrics.textLineFragmentPadding
		self.placeholderLabel.text = self.placeholderText
		self.placeholderLabel.textColor = .placeholderText
		self.placeholderLabel.numberOfLines = 0
		self.placeholderLabel.isUserInteractionEnabled = false
		self.placeholderLabel.isAccessibilityElement = false
		self.addSubview(self.placeholderLabel)
		NotificationCenter.default.addObserver(self, selector: #selector(updatePlaceholder), name: UITextView.textDidChangeNotification, object: self)
		self.updatePlaceholder()
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.placeholderLabel.font = self.font
		self.placeholderLabel.textAlignment = self.textAlignment
		let padding = self.textContainer.lineFragmentPadding
		let width = max(0, self.bounds.width - self.textContainerInset.left - self.textContainerInset.right - padding * 2)
		let size = self.placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
		self.placeholderLabel.frame = CGRect(x: self.textContainerInset.left + padding, y: self.textContainerInset.top, width: width, height: size.height)
	}

	@objc private func updatePlaceholder() {
		self.placeholderLabel.isHidden = !(self.text ?? "").isEmpty
		self.setNeedsLayout()
	}
}
