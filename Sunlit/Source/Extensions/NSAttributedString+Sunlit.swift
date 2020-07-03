//
//  NSAttributedString+Sunlit.swift
//  Sunlit
//
//  Created by Jonathan Hays on 7/2/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

extension NSAttributedString {
	
	func html() -> NSAttributedString {

		if let cachedValue = NSAttributedStringCache.get(self.string) {
			return cachedValue
		}
		
		let htmlData = self.string.data(using: .utf16)!
		if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
			NSAttributedStringCache.set(attributedString, for: self.string)
			return attributedString
		}

		return self
	}
}

// We provide a cache for NSAttributedStrings because we use them frequently from HTML formatting which is a very expensive operation.
class NSAttributedStringCache {
	
	static func get(_ key : String) -> NSAttributedString? {
		return objectCache.object(forKey: key as NSString)
	}
	
	static func set(_ value : NSAttributedString, for key: String) {
		objectCache.setObject(value, forKey: key as NSString)
	}
	
	static let objectCache = NSCache<NSString, NSAttributedString>()
}

