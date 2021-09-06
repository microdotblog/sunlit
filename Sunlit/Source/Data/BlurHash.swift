//
//  BlurHash.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/5/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwift
import BlurHash

class BlurHash {

	static func precalculate(_ hash : String) {
		if !UUDataCache.shared.dataExists(for: hash) {
			let size = CGSize(width: 64.0, height: 64.0)
			if let image = UIImage(blurHash: hash, size: size) {
				UURemoteImage.shared.setImage(image, for: hash)
			}
		}
	}

}

