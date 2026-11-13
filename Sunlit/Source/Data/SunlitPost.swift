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

class SunlitPost : SnippetsPost {
	
	// Add extra fields that assists with the native display of the post
	var aspectRatio : Float = 0.0
	var altText : [String] = []
	var images : [String] = []
	var videos: [Int: String] = [:]
	private lazy var caption = Self.captionHTML(self.htmlText)
	var htmlString: String {
		return Self.addTextStyle(string: self.caption, font: .preferredFont(forTextStyle: .body), textColor: .label)
	}
	var attributedText: NSAttributedString {
		return NSAttributedString(string: self.htmlString).html()
	}

	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	private static let miniThumbnailsURL = "https://micro.blog/photos/50/"
	
	static func create(_ snippet: SnippetsPost, cacheAuthor: Bool = true) -> SunlitPost {
		let post = SunlitPost()
		post.defaultPhoto = snippet.defaultPhoto
		post.identifier = snippet.identifier
		post.owner = cacheAuthor ? SnippetsUser.save(snippet.owner) : snippet.owner
		post.htmlText = snippet.htmlText
		post.path = snippet.path
		post.publishedDate = snippet.publishedDate
		post.hasConversation = snippet.hasConversation
		post.replies = snippet.replies
		post.isDraft = snippet.isDraft
		post.isBookmark = snippet.isBookmark

		if let document = try? cleanDocument(post.htmlText) {
			let elements = mediaElements(in: document)
			post.setMedia(from: elements)
			post.caption = captionHTML(document, removing: elements)
		}
		return post
	}

	private func setMedia(from elements: [Element]) {
		var aspectRatio: Float = 0
		let defaultWidth = self.defaultPhoto["width"] as? Int ?? 0
		let defaultHeight = self.defaultPhoto["height"] as? Int ?? 0

		for element in elements {
			let source = Self.imageTag(tag: "src", element)
			if element.tagName() == "video" {
				self.videos[self.images.count] = source
				self.images.append(Self.imageTag(tag: "poster", element))
			} else {
				self.images.append(source.replacingOccurrences(of: Self.miniThumbnailsURL, with: ""))
				if defaultWidth > 0 && defaultHeight > 0 {
					aspectRatio = max(aspectRatio, Float(defaultHeight) / Float(defaultWidth))
				}
			}
			self.altText.append(Self.imageTag(tag: "alt", element))

			let width = (Self.imageTag(tag: "width", element) as NSString).integerValue
			let height = (Self.imageTag(tag: "height", element) as NSString).integerValue
			if width > 0 && height > 0 {
				aspectRatio = max(aspectRatio, Float(height) / Float(width))
			}
		}
		self.aspectRatio = aspectRatio > 0 ? aspectRatio : 1
	}

	private static func cleanDocument(_ html: String) throws -> Document {
		let allowedList = try AllowedList.basicWithImages()
		_ = try allowedList.removeTags("p")
		_ = try allowedList.addAttributes("img", "class")
		_ = try allowedList.addTags("video").addAttributes("video", "src", "width", "height", "alt", "poster")
		let document = try SwiftSoup.parseBodyFragment(html)
		return try Cleaner(allowedList).clean(document)
	}

	private static func captionHTML(_ html: String) -> String {
		guard let document = try? cleanDocument(html) else { return "" }
		return captionHTML(document, removing: mediaElements(in: document))
	}

	private static func captionHTML(_ document: Document, removing media: [Element]) -> String {
		for element in media {
			try? element.remove()
		}
		return (try? document.body()?.html()) ?? ""
	}

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
	
	private static func mediaElements(in document: Document) -> [Element] {
		let elements = (try? document.select("img[src], video[src]"))?.array() ?? []
		return elements.filter { element in
			let source = imageTag(tag: "src", element)
			if element.tagName() == "img" &&
				(source.contains("/images/core/emoji") || element.hasClass("custom_emoji")) {
				let replacement = Element(Tag("b"), "")
				_ = try? replacement.appendText(imageTag(tag: "alt", element))
				try? element.parent()?.replaceChild(element, replacement)
				return false
			}
			return !source.isEmpty
		}
	}

	private static func imageTag(tag : String, _ element : Element) -> String {
		if let attributes = element.getAttributes() {
			let value = attributes.get(key: tag)
			return value
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


