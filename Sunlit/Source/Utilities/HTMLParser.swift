//
//  HTMLParser.swift
//  Sunlit
//
//  Created by Jonathan Hays on 9/13/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import Foundation
import SwiftSoup

class HTMLParser {

	let html : String

	init(_ text : String)
	{
		self.html = text
	}

	func findImages() -> [String] {

		var foundImages : [String] = []

		if let document = try? SwiftSoup.parse(self.html) {
			let images = HTMLParser.findImageElements(document)

			for image in images {
				let source = HTMLParser.imageTag(tag: "src", image)
				//let altText = HTMLParser.imageTag(tag: "alt", image)
				//let width = HTMLParser.imageTag(tag: "width", image) as NSString
				//let height = HTMLParser.imageTag(tag: "height", image) as NSString
				foundImages.append(source)
			}
		}

		return foundImages
	}

	func findGlassDescription() -> String {

		var description = ""
		if let document = try? SwiftSoup.parse(self.html) {
			let paragraphs = HTMLParser.findParagraphElements(document)
			for paragraph in paragraphs {
				if let text = try? paragraph.attr("class") {
					if text.contains("description"),
					   let paragraphText = try? paragraph.text() {
						description = paragraphText
					}
				}
			}
		}

		return description
	}

	static private func imageTag(tag : String, _ element : Element) -> String {
		if let attributes = element.getAttributes() {
			let value = attributes.get(key: tag)
			return value
		}
		return ""
	}

	static private func findParagraphElements(_ document : Document) -> [Element] {
		var elements : [Element] = []

		if let srcs : Elements = try? document.select("p") {
			for paragraph in srcs.array() {
				elements.append(paragraph)
			}
		}

		return elements
	}

	static private func findImageElements(_ document : Document) -> [Element] {
		var elements : [Element] = []

		if let srcs : Elements = try? document.select("img[src]") {
			for image in srcs.array() {
				elements.append(image)
			}
		}

		return elements
	}

}

