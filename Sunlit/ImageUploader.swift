//
//  ImageUploader.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class ImageUploader {
	
	var imageQueue : [UIImage] = []
	var results : [UIImage : String] = [ : ]
	
	func uploadImages(_ images : [UIImage], completion: @escaping (Error?, [UIImage : String]) -> Void) {
		self.imageQueue = images
		self.results = [ : ]
		
		if self.imageQueue.count > 0 {
			self.processUploadQueue(completion)
		}
		else {
			completion(nil, self.results)
		}
	}
	
	func processUploadQueue(_ completion : @escaping (Error?, [UIImage : String]) -> Void) {

		let image = self.imageQueue.removeFirst()
		
		Snippets.shared.uploadImage(image: image) { (error, remotePath) in
			
			if let path = remotePath {
				self.results[image] = path
			
				if self.imageQueue.count > 0 {
					self.processUploadQueue(completion)
					return
				}
			}
			
			completion(error, self.results)
		}
	}
}
