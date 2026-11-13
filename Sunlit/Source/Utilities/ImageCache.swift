//
//  ImageCache.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import UUSwiftNetworking

class ImageCache {
	private static let displayQueue = DispatchQueue(label: "blog.micro.sunlit.image-display", qos: .userInitiated)
	private static let displayCache: NSCache<NSString, UIImage> = {
		let cache = NSCache<NSString, UIImage>()
		cache.totalCostLimit = 48 * 1024 * 1024
		return cache
	}()
	private static var displayRequests: [String: [(UIImage) -> Void]] = [:]

	// Share disk reads, downloads, and image preparation between prefetching and visible cells.
	// Callers receive prepared images on the main queue.
	static func loadForDisplay(_ path: String, completion: ((UIImage) -> Void)? = nil) {
		guard let url = URL(string: path), let scheme = url.scheme,
			  ["http", "https"].contains(scheme.lowercased()), url.host != nil else { return }

		if let image = self.displayCache.object(forKey: path as NSString) {
			completion?(image)
			return
		}

		self.displayQueue.async {
			if let image = self.displayCache.object(forKey: path as NSString) {
				DispatchQueue.main.async { completion?(image) }
				return
			}

			if self.displayRequests[path] != nil {
				if let completion { self.displayRequests[path]?.append(completion) }
				return
			}
			self.displayRequests[path] = completion.map { [$0] } ?? []

			self.fetch(path) { image in
				self.displayQueue.async {
					let callbacks = self.displayRequests.removeValue(forKey: path) ?? []
					guard let image else { return }

					let prepared = image.preparingForDisplay() ?? image
					let bitmap = prepared.cgImage
					let cost = (bitmap?.bytesPerRow ?? 0) * (bitmap?.height ?? 0)
					self.displayCache.setObject(prepared, forKey: path as NSString, cost: cost)
					DispatchQueue.main.async {
						for callback in callbacks { callback(prepared) }
					}
				}
			}
		}
	}

	
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
