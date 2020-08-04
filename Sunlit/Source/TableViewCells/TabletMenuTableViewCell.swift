//
//  TabletMenuTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/4/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class TabletMenuTableViewCell: UITableViewCell {

	@IBOutlet var iconImageView : UIImageView!
	@IBOutlet var titleLabel : UILabel!
	@IBOutlet var alertContainer : UIView!
	@IBOutlet var alertLabel : UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
