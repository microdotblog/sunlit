//
//  MediaUploader.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import UUSwift

class MediaLocation : NSObject {
	var path : String = ""
	var thumbnailPath : String = ""
}

class MediaUploader {
	
	var mediaQueue : [SunlitMedia] = []
	var results : [SunlitMedia : MediaLocation] = [ : ]
	var currentUpload : UUHttpRequest? = nil
    var completion : ((Error?, [SunlitMedia : MediaLocation]) -> Void)? = nil
	
	func cancelAll() {
		if let activeUpload = self.currentUpload {
			activeUpload.cancel()
		}
		
		self.currentUpload = nil
		self.mediaQueue.removeAll()
	}
	
	func uploadMedia(_ media : [SunlitMedia], completion: @escaping (Error?, [SunlitMedia : MediaLocation]) -> Void) {
        self.completion = completion
        self.mediaQueue = media
		self.results = [ : ]
		
		DispatchQueue.global(qos: .background).async {
			if self.mediaQueue.count > 0 {
				self.processUploadQueue()
			}
			else {
				completion(nil, self.results)
			}
		}
	}

    func dataUploaded(error : Error?, media : SunlitMedia) {

        if let path = media.publishedPath,
           let thumbnailPath = media.thumbnailPath {

            let location = MediaLocation()
            location.path = path
            location.thumbnailPath = thumbnailPath

            self.results[media] = location

            if self.mediaQueue.count > 0 {
                self.processUploadQueue()
                return
            }
        }

        DispatchQueue.main.async {
            if let completion = self.completion {
                completion(error, self.results)
            }
        }
    }

	
	func processUploadQueue() {

		let media = self.mediaQueue.removeFirst()

        // Check to see if this media has already been published...
        if media.publishedPath != nil {
            self.dataUploaded(error: nil, media: media)
            return
        }

		if media.type == .image {
            self.uploadImage(media)
		}
		else if media.type == .video {
			
			VideoTranscoder.exportVideo(sourceUrl: media.videoURL) { (error, videoURL) in
				if let data = try? Data(contentsOf: videoURL) {
                    self.uploadVideo(media, data)
				}
			}
		}
	}
	

	
	func uploadImage(_ media : SunlitMedia) {

        self.currentUpload = Snippets.shared.uploadImage(image: media.getImage()) { (error, remotePath) in

            if let path = remotePath {
                media.publishedPath = path
                media.thumbnailPath =  "https://micro.blog/photos/200/" + path
            }

            self.dataUploaded(error: error, media: media)

        }
	}
	
	func uploadVideo(_ media : SunlitMedia, _ data : Data) {

        self.currentUpload = Snippets.shared.uploadVideo(data: data) { (error, publishedPath, posterPath) in

            media.publishedPath = publishedPath
            media.thumbnailPath = posterPath

            self.dataUploaded(error: error, media: media)
        }
	}
}
