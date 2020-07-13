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
	
    static var requestorLookup : [ String : [NSObject] ] = [:]
    
	static let systemCache = NSCache<NSString, UIImage>()
	
	static func prefetch(_ path: String) -> UIImage? {
		
		if let image = ImageCache.systemCache.object(forKey: path as NSString) {
			return image
		}
		
		if UUDataCache.shared.doesDataExist(for: path) {
			if let imageData = UUDataCache.shared.data(for: path) {
				if let image = UIImage(data: imageData) {
					ImageCache.systemCache.setObject(image, forKey: path as NSString)
					return image
				}
			}
		}
		
		return nil
	}
	
	
    static func fetch(_ requestor : NSObject, _ path: String, completion: @escaping ((UIImage?) -> Void)) {
		
		if let image = ImageCache.prefetch(path) {
			completion(image)
			return
		}
        
        if var requestorArray = requestorLookup[path] {
            for object in requestorArray {
                if object == requestor {
                    return
                }
            }
            
            requestorArray.append(requestor)
        }
        else {
            requestorLookup[path] = [requestor]
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
