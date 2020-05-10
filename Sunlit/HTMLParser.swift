//
//  HTMLParser.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class SunlitUser : SnippetsUser {
	var formattedBio : NSAttributedString = NSAttributedString()
}


class SunlitPost {
	var aspectRatio : Float = 0.0
	var altText : [String] = []
	var images : [String] = []
	var publishedDate : Date? = nil
	var text : NSAttributedString = NSAttributedString(string: "")
	var owner = SunlitUser()
	
	var source : SnippetsPost = SnippetsPost()
}

class HTMLParser {
	
	static func parse(_ snippet : SnippetsPost, font : UIFont = UIFont.systemFont(ofSize: 14.0), textColor : UIColor = UIColor.label) -> SunlitPost {

		let html = addTextStyle(string: snippet.htmlText, font: font, textColor: textColor)
		
		var string = html
		
		if let whitelist = try? Whitelist.basicWithImages() {
			_ = try? whitelist.removeTags("p")
			_ = try? whitelist.addTags("style")
			if let cleanString = try? SwiftSoup.clean(html, whitelist) {
				string = cleanString
			}
		}
		
		let parsedEntry = SunlitPost()
		parsedEntry.source = snippet
		parsedEntry.owner = convertUser(user: snippet.owner, font: font, textColor: textColor)
		parsedEntry.publishedDate = snippet.publishedDate
		
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
	
	static func convertUser(user : SnippetsUser, font : UIFont = UIFont.systemFont(ofSize: 14.0), textColor : UIColor = UIColor.label) -> SunlitUser {
		let sunlitUser = SunlitUser()
		sunlitUser.fullName = user.fullName
		sunlitUser.userHandle = user.userHandle
		sunlitUser.pathToUserImage = user.pathToUserImage
		sunlitUser.pathToWebSite = user.pathToWebSite
		sunlitUser.bio = user.bio
		sunlitUser.formattedBio = NSAttributedString(string: sunlitUser.bio)

		let formattedBio = addTextStyle(string: user.bio, font: font, textColor: textColor)
		let htmlData = Data(formattedBio.utf8)
		if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
			sunlitUser.formattedBio = attributedString
		}

		return sunlitUser
	}
	
	static func addTextStyle(string : String, font : UIFont, textColor : UIColor) -> String {
		
		let cssString = "<style>" +
		"html *" +
		"{" +
		"font-size: \(font.pointSize)pt !important;" +
		"color: \(textColor.uuHexString) !important;" +
		"font-family: \(font.familyName), Helvetica !important;" +
		"}</style>"

		let text = cssString + string

		return text
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
	
	static func trimWhitespace(_ string: String) -> String {
		let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
		let breaksRemoved = trimmed.replaceAll(of: "<br>", with: "")
		
		return breaksRemoved
	}
	
}
