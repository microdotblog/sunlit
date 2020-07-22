//
//  SectionTextView.swift
//  Sunlit
//
//  Created by Manton Reece on 7/22/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SectionTextView: UITextView {

	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
	}
}
