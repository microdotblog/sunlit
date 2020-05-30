//
//  UIBarButtonItem+Sunlit.swift
//  Sunlit
//
//  Created by Manton Reece on 5/29/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

extension UIBarButtonItem {

	static func barButtonWithImage(named name: String, target: AnyObject, action: Selector) -> UIBarButtonItem {
		let img = UIImage(named: name)!
		let extra_tapping_space: CGFloat = 8
		let w = img.size.width + extra_tapping_space
		let v = UIImageView(frame: CGRect(x: 0, y: 0, width: w, height: img.size.height))
		v.image = img
		v.isAccessibilityElement = true
		v.accessibilityLabel = name.replaceAll(of: "_", with: " ")
		v.contentMode = .center
		
		let gesture = UITapGestureRecognizer(target: target, action: action)
		v.addGestureRecognizer(gesture)
		
		let item = UIBarButtonItem(customView: v)
		return item
	}

}
