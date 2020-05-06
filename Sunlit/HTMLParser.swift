//
//  HTMLParser.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

class Post {
	var aspectRatio : Float = 0.0
	var altText : [String] = []
	var images : [String] = []
	var text : NSAttributedString = NSAttributedString(string: "")
}

class HTMLParser {
	
	static func parse(_ string : String) -> Post {
		
		let parsedEntry = Post()
		
		if let document = try? SwiftSoup.parse(string) {
			let images = findImageElements(document)
			let text = stripImages(document, images)
			
			let htmlData = Data(text.utf8)
			if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
				parsedEntry.text = attributedString
			}
			else {
				parsedEntry.text = NSAttributedString(string: text)
			}

			
			var aspectRatio : Float = 0.0
			
			for image in images {
				parsedEntry.images.append(imageTag(tag: "src", image))
				parsedEntry.altText.append(imageTag(tag: "alt", image))
			
				let width = imageTag(tag: "width", image) as NSString
				let height = imageTag(tag: "height", image) as NSString
			
				if width.integerValue > 0 && height.integerValue > 0 {
					let ratio = height.floatValue / width.floatValue
					if ratio > aspectRatio {
						aspectRatio = ratio
					}
				}
			}
			
			if aspectRatio == 0.0 {
				aspectRatio = 1.0
			}
			
			parsedEntry.aspectRatio = aspectRatio
		}
		
		return parsedEntry
	}
	
	static func findImageElements(_ document : Document) -> [Element] {
		var elements : [Element] = []
		
		if let srcs : Elements = try? document.select("img[src]") {
			let emojiImages = ["mini_thumbnail", "wp-smiley"]
			for image in srcs.array() {
				
				// Skip emoji images...
				if let className = try? image.className(), emojiImages.contains(className) {
					continue
				}

				elements.append(image)
			}
		}

		return elements
	}
	
	static func imageTag(tag : String, _ element : Element) -> String {
		
		if let attributes = element.attributes {
			let value = attributes.get(key: tag)
			return value
		}
		
		return ""
	}
		
	static func stripImages(_ document : Document, _ images : [Element]) -> String {
		
		for image in images {
			try? image.remove()
		}
		
		if let text = try? document.html() {
			return text
		}

		return ""
	}
	
	static func stripImageTags(_ string : String, _ images : [Element]) -> String {
		
		var parsedString = string
		
		for image in images {
			var html = try? image.html()
			if html?.count == 0 {
				html = try? image.outerHtml()
			}
			parsedString = parsedString.replacingOccurrences(of: html ?? "", with: "")
		}

		return parsedString
	}
	
}
