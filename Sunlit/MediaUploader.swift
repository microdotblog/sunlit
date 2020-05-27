//
//  MediaUploader.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class MediaUploader {
	
	var mediaQueue : [SunlitMedia] = []
	var results : [SunlitMedia : String] = [ : ]
	
	func uploadMedia(_ media : [SunlitMedia], completion: @escaping (Error?, [SunlitMedia : String]) -> Void) {
		self.mediaQueue = media
		self.results = [ : ]
		
		if self.mediaQueue.count > 0 {
			self.processUploadQueue(completion)
		}
		else {
			completion(nil, self.results)
		}
	}
	
	func processUploadQueue(_ completion : @escaping (Error?, [SunlitMedia : String]) -> Void) {

		let media = self.mediaQueue.removeFirst()
		
		if media.type == .image {
			Snippets.shared.uploadImage(image: media.getImage()) { (error, remotePath) in
			
				if let path = remotePath {
					self.results[media] = path
			
					if self.mediaQueue.count > 0 {
						self.processUploadQueue(completion)
						return
					}
				}
			
				completion(error, self.results)
			}
		}
		else if media.type == .video {
			if let data = try? Data(contentsOf: media.videoURL) {
				Snippets.shared.uploadVideo(data: data) { (error, publishedPath, posterPath) in
					if let path = publishedPath {
						self.results[media] = path
				
						if self.mediaQueue.count > 0 {
							self.processUploadQueue(completion)
							return
						}
					}
					completion(error, self.results)
				}				
			}

		}
	}
}
