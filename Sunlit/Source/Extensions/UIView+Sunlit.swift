//
//  UIView+Sunlit.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/31/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

extension UIView {

	func safeAreaTop() -> CGFloat {
		var superview = self.superview

		var safeAreaTop : CGFloat = self.safeAreaInsets.top
		
		while superview != nil {
			if superview!.safeAreaInsets.top > safeAreaTop {
				safeAreaTop = superview!.safeAreaInsets.top
			}
			superview = superview?.superview
		}
		
		return safeAreaTop
	}

	func safeAreaBottom() -> CGFloat {

		var superview = self.superview
		var safeAreaBottom : CGFloat = self.safeAreaInsets.bottom
		
		while superview != nil {
			if superview!.safeAreaInsets.bottom > safeAreaBottom {
				safeAreaBottom = superview!.safeAreaInsets.bottom
			}
			superview = superview?.superview
		}
		
		return safeAreaBottom
	}

	
	func constrainAllSides(_ view: UIView) {
		self.constrainLeft(view: view)
		self.constrainRight(view: view)
		self.constrainTop(view: view)
		self.constrainBottom(view: view)
	}
	
	func constrainCenter(view : UIView) {
		let center_x_constraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
		let center_y_constraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
		center_x_constraint.isActive = true
		center_y_constraint.isActive = true
	}
	
	func constrainWidth(view: UIView) {
		let width_constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0.0)
		width_constraint.isActive = true
	}

	func constrainHeight(view: UIView) {
		let width_constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0.0)
		width_constraint.isActive = true
	}

	func constrainLeft(view: UIView, offset : CGFloat = 0.0, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let left_constraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: offset)
		left_constraint.isActive = true
		if let completion = completion {
			completion(left_constraint)
		}
	}
	
	func constrainRight(view: UIView, offset : CGFloat = 0.0, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let right_constraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: offset)
		right_constraint.isActive = true
		if let completion = completion {
			completion(right_constraint)
		}
	}
	
	func constrainTop(view: UIView, offset : CGFloat = 0.0, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let top_constraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: offset)
		top_constraint.isActive = true
		if let completion = completion {
			completion(top_constraint)
		}
	}
	
	func constrainTop(bottomOfView view: UIView, offset : CGFloat = 0.0, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let top_constraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: offset)
		top_constraint.isActive = true
		if let completion = completion {
			completion(top_constraint)
		}
	}
	
	func constrainBottom(view: UIView, offset : CGFloat = 0.0, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let bottom_constraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: offset)
		bottom_constraint.isActive = true
		if let completion = completion {
			completion(bottom_constraint)
		}
	}
	
	func constrainHeight(_ height: CGFloat, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let height_constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
		height_constraint.isActive = true
		if let completion = completion {
			completion(height_constraint)
		}
	}

	func constrainWidth(_ width: CGFloat, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let height_constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
		height_constraint.isActive = true
		if let completion = completion {
			completion(height_constraint)
		}
	}
	
	func clearConstraints() {
		let old_constraints = self.constraints
		self.removeConstraints(old_constraints)
		if let parent_view = self.superview {
			let parent_constraints = parent_view.constraints
			for c in parent_constraints {
				if let first = c.firstItem as? UIView {
					if first == self {
						parent_view.removeConstraint(c)
					}
				}
				if let second = c.secondItem as? UIView {
					if second == self {
						parent_view.removeConstraint(c)
					}
				}
			}
		}
	}
	
}
