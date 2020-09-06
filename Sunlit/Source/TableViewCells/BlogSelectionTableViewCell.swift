//
//  BlogSelectionTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class BlogSelectionTableViewCell: UITableViewCell {
    
    @IBOutlet var selectionImage : UIImageView!
    @IBOutlet var blogTitle : UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.selectionImage.image = UIImage(systemName: "checkmark.circle.fill")
        }
        else {
            self.selectionImage.image = UIImage(systemName: "circle")
        }
    }

}
