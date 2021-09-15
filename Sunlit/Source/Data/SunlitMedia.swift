//
//  SunlitMedia.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/27/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class SunlitMedia : NSObject {
	
	enum type {
		case image
		case video
	}
	
	init(withImage: UIImage, fileType: String = "public.jpeg") {
		super.init()
		self.fileType = fileType
		self.type = .image
		self.image = withImage
	}
	
	init(withVideo: URL) {
		super.init()
		self.type = .video
		self.videoURL = withVideo
		self.image = self.generateVideoThumbnail()
	}
	
	func generateVideoThumbnail() -> UIImage? {
		let asset = AVAsset(url: self.videoURL)
		let imageGenerator = AVAssetImageGenerator(asset: asset)
		imageGenerator.appliesPreferredTrackTransform = true
		let thumbnailTime = CMTimeMake(value: 2, timescale: 1)
		do {
			let cgImage = try imageGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
			let image = UIImage(cgImage: cgImage)
			return image
		}
		catch {
			print(error.localizedDescription)
		}
		return nil
	}
	
	func getImage() -> UIImage {
		return image
	}

	var type : type = .image
	var image : UIImage!
	var altText : String = ""
	var videoURL : URL = URL(fileURLWithPath: "")
    var publishedPath : String? = nil
    var thumbnailPath : String? = nil
	var fileType : String = "public.jpeg"
}
