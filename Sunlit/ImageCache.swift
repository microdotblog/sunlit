//
//  ImageCache.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ImageCache {
	
	static let systemCache = NSCache<NSString, UIImage>()
	
	static func prefetch(_ path: String) -> UIImage? {
		
		if let image = ImageCache.systemCache.object(forKey: path as NSString) {
			return image
		}
		
		if let imageData = UURemoteData.shared.data(for: path) {
			if let image = UIImage(data: imageData) {
				ImageCache.systemCache.setObject(image, forKey: path as NSString)
				return image
			}
		}
		
		return nil
	}
	
	
	static func fetch(_ path: String, completion: @escaping ((UIImage?) -> Void)) {
		
		if let image = ImageCache.prefetch(path) {
			completion(image)
			return
		}
		
		_ = UURemoteData.shared.data(for: path) { (data, error) in
			if let imageData = data {
				if let image = UIImage(data: imageData) {
					ImageCache.systemCache.setObject(image, forKey: path as NSString)
					completion(image)
					return
				}
			}
			
			completion(nil)
		}
	}
}
