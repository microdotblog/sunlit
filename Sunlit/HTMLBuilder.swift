//
//  HTMLBuilder.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/26/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class HTMLBuilder {

	static func createHTML(sections : [SunlitComposition], imagePathDictionary : [UIImage : String]) -> String {
		var html = ""
		
		for index in 0 ... sections.count - 1 {
			let section = sections[index]
			html = html + HTMLBuilder.htmlForComposition(section, imagePathDictionary)
			
			if index < sections.count - 1 {
				html = html + "\n\n"
			}
		}
		
		return html
	}

	static func htmlForComposition(_ section : SunlitComposition, _ imageDictionary : [UIImage : String]) -> String {
		var html = ""
		
		if section.text.count > 0 {
			html = html + section.text
			html = html + "\n\n"
		}
		
		var index = 0
		let num_images = section.images.count
		for image in section.images {
			let imagePath = imageDictionary[image]!
			let imageWidth = "\(image.size.width)"
			let imageHeight = "\(image.size.height)"
			let imageAlt = section.altText[index]
			var imageText = ""
			
			if num_images > 1 {
				imageText = "<img src=\"{{url}}\" width=\"{{width}}\" height=\"{{height}}\" alt=\"{{alt}}\" style=\"display: inline-block; max-height: 200px; width: auto; padding: 1px;\" class=\"sunlit_image\" />"
			}
			else {
				imageText = "<img src=\"{{url}}\" width=\"{{width}}\" height=\"{{height}}\" alt=\"{{alt}}\" style=\"height: auto;\" class=\"sunlit_image\" />"
			}
			
			imageText = imageText.replacingOccurrences(of: "{{url}}", with: imagePath)
			imageText = imageText.replacingOccurrences(of: "{{width}}", with: imageWidth)
			imageText = imageText.replacingOccurrences(of: "{{height}}", with: imageHeight)
			imageText = imageText.replacingOccurrences(of: "{{alt}}", with: imageAlt)
			
			html = html + imageText
			index = index + 1
		}
		
		return html
	}
	
}
