//
//  ImageCache.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwift

class ImageCache {
	
	
	static func prefetch(_ path: String) -> UIImage? {
        if UURemoteImage.shared.isDownloaded(for: path) {
            return UURemoteImage.shared.image(for: path)
        }
		
		return nil
	}
	
	
    static func fetch(_ path: String, completion: @escaping ((UIImage?) -> Void)) {

        let image = UURemoteImage.shared.image(for: path, remoteLoadCompletion: { (image, error) in
            completion(image)
        })
        
        if let img = image {
            completion(img)
        }
	}
}
