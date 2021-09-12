//
//  NearbyLocationsTableViewCell.swift
//  Sunlit
//
//  Created by Jonathan Hays on 8/8/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit
import MapKit

class NearbyLocationsTableViewCell: UITableViewCell {

	@IBOutlet var locationNameLabel : UILabel!
	@IBOutlet var categoryImageView : UIImageView!
	@IBOutlet var map : MKMapView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
