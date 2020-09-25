//
//  BlogSelectionAddNewCell.swift
//  Sunlit
//
//  Created by Manton Reece on 9/24/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class BlogSelectionAddNewCell: UITableViewCell {

	@IBOutlet var titleField : UILabel!

	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.setupSelectionBackground()
    }

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	func setupSelectionBackground() {
		let selected_view = UIView(frame: self.bounds)
		selected_view.backgroundColor = UIColor(named: "color_cell_selection")
		self.selectedBackgroundView = selected_view
	}
	
}
