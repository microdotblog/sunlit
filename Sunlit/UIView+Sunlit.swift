//
//  UIView+Sunlit.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/31/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

extension UIView {
	
	func constrainAllSides(_ view: UIView) {
		self.constrainLeft(view: view)
		self.constrainRight(view: view)
		self.constrainTop(view: view)
		self.constrainBottom(view: view)
	}
	
	func constrainLeft(view: UIView, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let left_constraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
		left_constraint.isActive = true
		if let completion = completion {
			completion(left_constraint)
		}
	}
	
	func constrainRight(view: UIView, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let right_constraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
		right_constraint.isActive = true
		if let completion = completion {
			completion(right_constraint)
		}
	}
	
	func constrainTop(view: UIView, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let top_constraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
		top_constraint.isActive = true
		if let completion = completion {
			completion(top_constraint)
		}
	}
	
	func constrainTop(bottomOfView view: UIView, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let top_constraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
		top_constraint.isActive = true
		if let completion = completion {
			completion(top_constraint)
		}
	}
	
	func constrainBottom(view: UIView, completion: ((NSLayoutConstraint) -> Void)? = nil) {
		let bottom_constraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
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
