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
	var selectedImage: UIImage?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.defaultImage = self.image(for: .normal)
		if let img = self.defaultImage {
			if let c = UIColor(named: "color_tab_selected") {
				self.selectedImage = img.withTintColor(c, renderingMode: .alwaysOriginal)
			}
		}
		
		self.setTitleColor(UIColor(named: "color_tab_normal"), for: .normal)
		self.setTitleColor(UIColor(named: "color_tab_normal"), for: .selected)
	}
	
	override func setImage(_ image: UIImage?, for state: UIControl.State) {
		super.setImage(image, for: state)

		if let img = image {
			if !img.isSymbolImage {
				self.defaultImage = nil
				self.selectedImage = nil
			}
		}
	}
	
    override var isSelected: Bool {
        didSet {
			if self.isSelected {
				self.setTitleColor(UIColor(named: "color_tab_selected"), for: .normal)
				self.setTitleColor(UIColor(named: "color_tab_selected"), for: .selected)
				
				if let img = self.selectedImage {
					if img.isSymbolImage {
						self.setImage(img, for: .normal)
						self.setImage(img, for: .selected)
					}
				}
			}
			else {
				self.setTitleColor(UIColor(named: "color_tab_normal"), for: .normal)
				self.setTitleColor(UIColor(named: "color_tab_normal"), for: .selected)

				if let img = self.defaultImage {
					if img.isSymbolImage {
						self.setImage(img, for: .normal)
						self.setImage(img, for: .selected)
					}
				}
			}
        }
    }
	
}
