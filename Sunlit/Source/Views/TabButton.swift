//
//  TabButton.swift
//  Sunlit
//
//  Created by Manton Reece on 7/11/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class TabButton: UIButton {

	var defaultImage: UIImage?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		if let imageview = self.findImageView() {
			self.defaultImage = imageview.image
		}
	}
	
	private func findSubviewOf(class c: AnyClass) -> AnyObject? {
		// title and image views are next to UIButton and not actually subviews
		if let superview = self.superview {
			for sub in superview.subviews {
				if sub.isKind(of: c) {
					return sub
				}
			}
		}
		
		return nil
	}

	private func findTitleField() -> UILabel? {
		if let field = self.findSubviewOf(class: UILabel.self) as? UILabel {
			return field
		}
		else {
			return nil
		}
	}
	
	private func findImageView() -> UIImageView? {
		if let imageview = self.findSubviewOf(class: UIImageView.self) as? UIImageView {
			return imageview
		}
		else {
			return nil
		}
	}
		
	func setImage(_ image: UIImage?) {
		if let imageview = self.findImageView() {
			imageview.image = image
		}
	}

	override func setImage(_ image: UIImage?, for state: UIControl.State) {
		if let imageview = self.findImageView() {
			imageview.image = image
		}
	}

    override var isSelected: Bool {
        didSet {
			if self.isSelected {
				if let field = self.findTitleField() {
					field.textColor = UIColor(named: "color_tab_selected")
				}
				
				if let imageview = self.findImageView() {
					imageview.tintColor = UIColor(named: "color_tab_selected")
				}
			}
			else {
				if let field = self.findTitleField() {
					field.textColor = UIColor(named: "color_tab_normal")
				}

				if let imageview = self.findImageView() {
					imageview.tintColor = UIColor(named: "color_tab_normal")
				}
			}
        }
    }
	
}
