//
//  BlurHash.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/5/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwiftCore
import UUSwiftNetworking
import UUSwiftImage
import BlurHash

class BlurHash {

	static func precalculate(_ hash : String, width: Int, height: Int) {
		if !UUDataCache.shared.dataExists(for: hash) {
			let size = CGSize(width: width, height: height)
			if let image = UIImage(blurHash: hash, size: size) {
				UURemoteImage.shared.memoryCache().setObject(image, forKey: hash as NSString)
			}
		}
	}

}

