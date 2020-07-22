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
		
		self.defaultImage = self.image(for: .normal)
	}
	
    override var isSelected: Bool {
        didSet {
			if self.isSelected {
				self.setTitleColor(UIColor(named: "color_tab_selected"), for: .normal)
				self.setTitleColor(UIColor(named: "color_tab_selected"), for: .selected)

//				self.setImage(self.defaultImage, for: .normal)
//				self.setImage(self.defaultImage, for: .selected)
			}
			else {
				self.setTitleColor(UIColor(named: "color_tab_normal"), for: .normal)
				self.setTitleColor(UIColor(named: "color_tab_normal"), for: .selected)

//				self.setImage(self.defaultImage, for: .normal)
//				self.setImage(self.defaultImage, for: .selected)
			}
        }
    }

	override func draw(_ rect: CGRect) {
		if self.isSelected {
//			let c = UIColor.white
//			c.set()
//
//			let r = self.contentRect(forBounds: self.bounds)
//
//			let path = UIBezierPath(roundedRect: r, cornerRadius: 10)
//			path.fill()
		}
		
		super.draw(rect)
	}
	
}
