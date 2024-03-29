//
//  SunlitPost.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets
import SwiftSoup
//import UUSwift

class SunlitPost : SnippetsPost {
	
	// Add extra fields that assists with the native display of the post
	var aspectRatio : Float = 0.0
	var altText : [String] = []
	var images : [String] = []
	var videos : [String:String] = [:]
	var htmlString : String = ""
	var attributedText : NSAttributedString = NSAttributedString(string: "")

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	// These are exclusion patterns in the image source that can help remove any images from displaying, like emojis.
	static let exclusionPatterns : [String] = ["/images/core/emoji"]
	static let miniThumbnailsURL = "https://micro.blog/photos/50/"
	
	static func create(_ snippet : SnippetsPost, font : UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body), textColor : UIColor = UIColor.label) -> SunlitPost {

		let html = addTextStyle(string: snippet.htmlText, font: font, textColor: textColor)
		
		var string = html
		
		// We create an allowedList for most of the html elements as well as strip out the image tags
		if let allowedList = try? AllowedList.basicWithImages() {
			_ = try? allowedList.removeTags("p")
			_ = try? allowedList.addTags("style")
			_ = try? allowedList.addTags("video").addAttributes("video", "src", "width", "height", "alt", "poster")
			if let cleanString = try? SwiftSoup.clean(html, allowedList) {
				string = cleanString
			}
		}

		// For now, we are going to keep the original snippet object
		let parsedEntry = SunlitPost()
		parsedEntry.defaultPhoto = snippet.defaultPhoto
		parsedEntry.identifier = snippet.identifier
		parsedEntry.owner = snippet.owner
		parsedEntry.htmlText = snippet.htmlText
		parsedEntry.path = snippet.path
		parsedEntry.publishedDate = snippet.publishedDate
		parsedEntry.hasConversation = snippet.hasConversation
		parsedEntry.replies = snippet.replies
		parsedEntry.isDraft = snippet.isDraft
        parsedEntry.isBookmark = snippet.isBookmark

		// Calling this both saves and merges any existing user info/data...
		parsedEntry.owner = SnippetsUser.save(snippet.owner)
		
		// Grab the published date...
		parsedEntry.publishedDate = snippet.publishedDate
		
		// Use SwiftSoup to parse the post.
		// We also calculate the aspect ratio from the width and height tags (if they exists) so that we can properly
		// size the table cells when it's time to display the images.
		if let document = try? SwiftSoup.parse(string) {
			let images = findImageElements(document)
			let videos = findVideoElements(document)
			let text = stripImagesAndVideos(document, images, videos)
			parsedEntry.htmlString = text
			
			var aspectRatio : Float = 0.0

			// Store the image paths and the alt-text objects (if they exist)
			for image in images {
				var source = imageTag(tag: "src", image)
				let altText = imageTag(tag: "alt", image)
				
				// expand the mini thumbnails
				if source.contains(miniThumbnailsURL) {
					source = source.replaceAll(of: miniThumbnailsURL, with: "")
				}
				
				parsedEntry.images.append(source)
				parsedEntry.altText.append(altText)
			
				let width = imageTag(tag: "width", image) as NSString
				let height = imageTag(tag: "height", image) as NSString

				if width.integerValue > 0 && height.integerValue > 0 {
					let ratio = height.floatValue / width.floatValue
					if ratio > aspectRatio {
						aspectRatio = ratio
					}
				}

				// Override what's in the HTML if we've already pre-calculated...
				let defaultPhotoHeight : Float = Float(parsedEntry.defaultPhoto["height"] as? Int ?? 0)
				let defaultPhotoWidth : Float = Float(parsedEntry.defaultPhoto["width"] as? Int ?? 0)
				if defaultPhotoWidth > 0 && defaultPhotoHeight > 0 && (width.floatValue != defaultPhotoWidth || height.floatValue != defaultPhotoHeight) {
					let ratio = defaultPhotoHeight / defaultPhotoWidth
					if ratio > aspectRatio {
						aspectRatio = ratio
					}
				}

			}
			
			for video in videos {
				let source = imageTag(tag: "src", video)
				let poster = imageTag(tag: "poster", video)
				let altText = imageTag(tag: "alt", video)
				let width = imageTag(tag: "width", video) as NSString
				let height = imageTag(tag: "height", video) as NSString

				parsedEntry.altText.append(altText)
				parsedEntry.videos[poster] = source
				parsedEntry.images.append(poster)
				if width.floatValue > 0.0 && height.floatValue > 0.0 {
					let ratio = height.floatValue / width.floatValue
					if ratio > aspectRatio {
						aspectRatio = ratio
					}
				}
			}

			
			// If there is no aspect ratio, we will default to a square/1.0 aspect ratio
			if aspectRatio == 0.0 {
				aspectRatio = 1.0
			}
			
			parsedEntry.aspectRatio = aspectRatio
		}
		
		parsedEntry.attributedText = NSAttributedString(string: parsedEntry.htmlString).html()
		
		return parsedEntry
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	static func addTextStyle(string : String, font : UIFont, textColor : UIColor) -> String {
		
		let cssString = """
		<style>
		body {
			color: \(textColor.uuHexString) !important;
			font-size: \(font.pointSize)px !important;
			font-family: system-ui !important;
		}
		</style>
		"""
		
		return cssString + string
	}
	
	static func findVideoElements(_ document : Document) -> [Element] {
		var elements : [Element] = []
		
		if let sources : Elements = try? document.select("video[src]") {
			for video in sources.array() {
				elements.append(video)
			}
		}
		
		return elements
	}
	
	static func findImageElements(_ document : Document) -> [Element] {
		var elements : [Element] = []
		
		if let srcs : Elements = try? document.select("img[src]") {
			for image in srcs.array() {
				
				var exclude = false

				for excludedPattern in SunlitPost.exclusionPatterns {
					
                    if let text = try? image.attr("src"),
                        text.contains(excludedPattern)
                    {
                        exclude = true

                        let alt : String = (try? image.attr("alt")) ?? ""
                        let replacementTag = Element(Tag("b"), "")

                        _ = try? replacementTag.appendText(alt)
                        
                        try? image.parent()?.replaceChild(image, replacementTag)
					}
				}


				if !exclude {
					elements.append(image)
				}
			}
		}

		return elements
	}
	
	static func imageTag(tag : String, _ element : Element) -> String {
		if let attributes = element.getAttributes() {
			let value = attributes.get(key: tag)
			return value
		}
		
		return ""
	}
		
	static func stripImagesAndVideos(_ document : Document, _ images : [Element], _ videos : [Element]) -> String {
		
		for image in images {
            try? image.remove()
		}
		
		for video in videos {
			try? video.remove()
		}
		
		if let text = try? document.html() {
			return text
		}

		return ""
	}
	
}


extension SunlitPost {
	
    var mentionedUsernames: [String] {
        // Setting up our state, which is any partial name that we’re
        // currently parsing, and an array of all names found.
        var partialName: String?
		var names : [String] = ["@" + owner.username]

        // A nested parsing function, that we’ll apply to each
        // character within the string.
        func parse(_ character: Character) {
            if var name = partialName {
                guard character.isLetter else {
                    // If we encounter a non-letter character
                    // while parsing a name, it means that the
                    // name is finished, and we can add it to
                    // our array (if non-empty):
                    if !name.isEmpty {
                        names.append("@" + name)
                    }

                    // Reset our state, and parse the character
                    // again, since it might be an @-sign.
                    partialName = nil
                    return parse(character)
                }

                name.append(character)
                partialName = name
            } else if character == "@" {
                // Set an empty state, to signal to our above
                // code that it’s time to start parsing a name.
                partialName = ""
            }
        }

        // Apply our parsing function to each character
		self.htmlText.forEach(parse)

        // Once we’ve reached the end, we’ll make sure to
        // capture any name that was previously found.
        if let lastName = partialName, !lastName.isEmpty {
            names.append("@" + lastName)
        }

        return names
    }
}

extension SunlitPost {
    func loadDraftedText() -> String {
        if let string = Settings.object(forKey: "\(self.identifier)-DRAFT") as? String {
            return string
        }

        return ""
    }

    func saveDraftedReply(_ text : String) {
        Settings.setValue(text, forKey: "\(self.identifier)-DRAFT")
    }
}


