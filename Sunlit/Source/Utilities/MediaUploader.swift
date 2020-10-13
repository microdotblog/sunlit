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

    static let maxUploads = 4

	var mediaQueue : [SunlitMedia] = []
	var results : [SunlitMedia : MediaLocation] = [ : ]
    var completion : ((Error?, [SunlitMedia : MediaLocation]) -> Void)? = nil
    var currentUploads : [UUHttpRequest] = []

	func cancelAll() {

        for activeUpload in currentUploads {
            activeUpload.cancel()
        }
        self.currentUploads.removeAll()
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
        }

        if self.currentUploads.count == 0 && self.mediaQueue.count == 0 && error == nil {
            DispatchQueue.main.async {
                if let completion = self.completion {
                    completion(error, self.results)
                }
            }
        }
        else {
            self.processUploadQueue()
        }
    }

	
	func processUploadQueue() {

        while self.mediaQueue.count > 0 && self.currentUploads.count < MediaUploader.maxUploads {

            let media = self.mediaQueue.removeFirst()

            // Check to see if this media has already been published...
            if media.publishedPath != nil {
                self.dataUploaded(error: nil, media: media)
            }
            else if media.type == .image {
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
	}
	
	func uploadImage(_ media : SunlitMedia) {

        var upload : UUHttpRequest? = nil
        upload = Snippets.shared.uploadImage(image: media.getImage()) { (error, remotePath) in

            if let path = remotePath {
                media.publishedPath = path
                media.thumbnailPath =  "https://micro.blog/photos/200/" + path
            }

            if let index = self.currentUploads.firstIndex(of: upload!) {
                self.currentUploads.remove(at: index)
            }
            self.dataUploaded(error: error, media: media)
        }

        if let upload = upload {
            self.currentUploads.append(upload)
        }
	}
	
	func uploadVideo(_ media : SunlitMedia, _ data : Data) {

        var upload : UUHttpRequest? = nil
        upload = Snippets.shared.uploadVideo(data: data) { (error, publishedPath, posterPath) in

            media.publishedPath = publishedPath
            media.thumbnailPath = posterPath

            if let index = self.currentUploads.firstIndex(of: upload!) {
                self.currentUploads.remove(at: index)
            }
            self.dataUploaded(error: error, media: media)
        }

        if let upload = upload {
            self.currentUploads.append(upload)
        }
	}
}
