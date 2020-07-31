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
	
	func cancelAll() {
		if let activeUpload = self.currentUpload {
			activeUpload.cancel()
		}
		
		self.currentUpload = nil
		self.mediaQueue.removeAll()
	}
	
	func uploadMedia(_ media : [SunlitMedia], completion: @escaping (Error?, [SunlitMedia : MediaLocation]) -> Void) {
		self.mediaQueue = media
		self.results = [ : ]
		
		DispatchQueue.global(qos: .background).async {
			if self.mediaQueue.count > 0 {
				self.processUploadQueue(completion)
			}
			else {
				completion(nil, self.results)
			}
		}
	}
	
	
	func processUploadQueue(_ completion : @escaping (Error?, [SunlitMedia : MediaLocation]) -> Void) {

		let media = self.mediaQueue.removeFirst()
		
		if media.type == .image {
			if Settings.usesExternalBlog() && PublishingConfiguration.current.hasConfigurationForExternal() {
				self.uploadImageToXMLRPC(media, completion)
			}
			else {
				self.uploadImageToMicropub(media, completion)
			}
		}
		else if media.type == .video {
			
			VideoTranscoder.exportVideo(sourceUrl: media.videoURL) { (error, videoURL) in
				if let data = try? Data(contentsOf: videoURL) {
					if Settings.usesExternalBlog() && PublishingConfiguration.current.hasConfigurationForExternal() {
						self.uploadVideoToXMLRPC(media, data, completion)
					}
					else {
						self.uploadVideoToMicropub(media, data, completion)
					}
				}
			}
		}
	}
	

	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	func uploadImageToXMLRPC(_ media : SunlitMedia, _ completion : @escaping (Error?, [SunlitMedia : MediaLocation]) -> Void) {

		if let identity = PublishingConfiguration.current.xmlRPCIdentity() {
			let request = SnippetsXMLRPCRequest.publishPhotoRequest(identity: identity)
			
			self.currentUpload = Snippets.shared.uploadImage(image: media.image, request: request) { (error, remotePath, pubilshedIdentifier) in
				if let path = remotePath {
					let location = MediaLocation()
					location.path = path
					location.thumbnailPath = path
							
					self.results[media] = location
					
					if self.mediaQueue.count > 0 {
						self.processUploadQueue(completion)
						return
					}

				}
				
				DispatchQueue.main.async {
					completion(error, self.results)
				}
			}
		}
	}

	func uploadVideoToXMLRPC(_ media : SunlitMedia, _ data : Data, _ completion : @escaping (Error?, [SunlitMedia : MediaLocation]) -> Void) {

		if let identity = PublishingConfiguration.current.xmlRPCIdentity() {
			let request = SnippetsXMLRPCRequest.publishPhotoRequest(identity: identity)
			
			self.currentUpload = Snippets.shared.uploadVideo(data: data, request: request) { (error, remotePath, publishedIdentifier) in
				if let path = remotePath {
					//let thumbnailPath = posterPath {
					
					let location = MediaLocation()
					location.path = path
					
					// TODO: How do we get a poster path for XMLRPC videos?
					//location.thumbnailPath = thumbnailPath
					self.results[media] = location
				
					if self.mediaQueue.count > 0 {
						self.processUploadQueue(completion)
						return
					}
				}
					
				DispatchQueue.main.async {
					completion(error, self.results)
				}
			}
		}
	}
	
	func uploadImageToMicropub(_ media : SunlitMedia, _ completion : @escaping (Error?, [SunlitMedia : MediaLocation]) -> Void) {
		self.currentUpload = Snippets.shared.uploadImage(image: media.getImage()) { (error, remotePath) in
		
			if let path = remotePath {
				let location = MediaLocation()
				location.path = path
				location.thumbnailPath = path
				
				self.results[media] = location
		
				if self.mediaQueue.count > 0 {
					self.processUploadQueue(completion)
					return
				}
			}
		
			DispatchQueue.main.async {
				completion(error, self.results)
			}
		}
	}
	
	func uploadVideoToMicropub(_ media : SunlitMedia, _ data : Data, _ completion : @escaping (Error?, [SunlitMedia : MediaLocation]) -> Void) {
		self.currentUpload = Snippets.shared.uploadVideo(data: data) { (error, publishedPath, posterPath) in
			if let path = publishedPath,
				let thumbnailPath = posterPath {
				let location = MediaLocation()
				location.path = path
				location.thumbnailPath = thumbnailPath
				self.results[media] = location
		
				if self.mediaQueue.count > 0 {
					self.processUploadQueue(completion)
					return
				}
			}
			
			DispatchQueue.main.async {
				completion(error, self.results)
			}
		}
	}
}
