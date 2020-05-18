//
//  SunlitPost.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/5/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit


class SunlitPost : SnippetsPost {
	
	// Add extra fields that assists with the native display of the post
	var aspectRatio : Float = 0.0
	var altText : [String] = []
	var images : [String] = []
	var text : NSAttributedString = NSAttributedString(string: "")

	//var source : SnippetsPost = SnippetsPost()
    var mentionedUsernames: [String] {
        // Setting up our state, which is any partial name that we’re
        // currently parsing, and an array of all names found.
        var partialName: String?
		var names : [String] = ["@" + owner.userHandle]

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
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	static func create(_ snippet : SnippetsPost, font : UIFont = UIFont.systemFont(ofSize: 14.0), textColor : UIColor = UIColor.label) -> SunlitPost {

		let html = addTextStyle(string: snippet.htmlText, font: font, textColor: textColor)
		
		var string = html
		
		// We whitelist most of the html elements as well as strip out the image tags
		if let whitelist = try? Whitelist.basicWithImages() {
			_ = try? whitelist.removeTags("p")
			_ = try? whitelist.addTags("style")
			if let cleanString = try? SwiftSoup.clean(html, whitelist) {
				string = cleanString
			}
		}

		// For now, we are going to keep the original snippet object
		let parsedEntry = SunlitPost()
		parsedEntry.identifier = snippet.identifier
		parsedEntry.owner = snippet.owner
		parsedEntry.htmlText = snippet.htmlText
		parsedEntry.path = snippet.path
		parsedEntry.publishedDate = snippet.publishedDate
		parsedEntry.hasConversation = snippet.hasConversation
		parsedEntry.replies = snippet.replies
		parsedEntry.isDraft = snippet.isDraft

		// Calling this both saves and merges any existing user info/data...
		parsedEntry.owner = SnippetsUser.save(snippet.owner)
		
		// Grab the published date...
		parsedEntry.publishedDate = snippet.publishedDate
		
		// Use SwiftSoup to parse the post.
		// We also calculate the aspect ratio from the width and height tags (if they exists) so that we can properly
		// size the table cells when it's time to display the images.
		if let document = try? SwiftSoup.parse(string) {
			let images = findImageElements(document)
			let text = stripImages(document, images)
			
			let htmlData = text.data(using: .utf16)!
			if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
				parsedEntry.text = attributedString
			}
			else {
				parsedEntry.text = NSAttributedString(string: text)
			}

			var aspectRatio : Float = 0.0
			
			// Store the image paths and the alt-text objects (if they exist)
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
			
			// If there is no aspect ratio, we will default to a square/1.0 aspect ratio
			if aspectRatio == 0.0 {
				aspectRatio = 1.0
			}
			
			parsedEntry.aspectRatio = aspectRatio
		}
		
		return parsedEntry
	}
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	static func addTextStyle(string : String, font : UIFont, textColor : UIColor) -> String {
		
		let cssString = "<style>" +
		"html *" +
		"{" +
		"font-size: \(font.pointSize)pt !important;" +
		"color: \(textColor.uuHexString) !important;" +
		"font-family: \(font.familyName), Helvetica !important;" +
		"}</style>"

		return cssString + string
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
	
}

