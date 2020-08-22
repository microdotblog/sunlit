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
	
	//static var requestorLookup : [ String : [NSObject] ] = [:]
	
	static func prefetch(_ path: String) -> UIImage? {
        if UURemoteImage.shared.isDownloaded(for: path) {
            return UURemoteImage.shared.image(for: path)
        }
		
		return nil
	}
	
	
	static func fetch(_ requestor : NSObject, _ path: String, completion: @escaping ((UIImage?) -> Void)) {

		/*if var requestorArray = ImageCache.requestorLookup[path] {
			for object in requestorArray {
				if object == requestor {
					return
				}
			}
					
			requestorArray.append(requestor)
		}
		else {
			ImageCache.requestorLookup[path] = [requestor]
		}*/
	
        let image = UURemoteImage.shared.image(for: path, remoteLoadCompletion: { (image, error) in
            completion(image)
        })
        
        if let img = image {
            completion(img)
        }
	}
}
