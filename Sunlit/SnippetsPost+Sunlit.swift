//
//  SnippetsPost+Sunlit.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/16/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation
import Snippets


extension SnippetsPost {
	
	func dictionary() -> [String : Any]
	{
		var dictionary : [String : Any] = [:]
		var properties : [String : Any] = [:]
		var microblogDictionary : [String : Any] = [:]

		properties["url"] = self.path
		properties["content"] = self.htmlText
		properties["published"] = [ self.publishedDate ]
		properties["post-status"] = self.isDraft ? "draft" : "published"
		dictionary["id"] = self.identifier
		dictionary["content_html"] = self.htmlText
		dictionary["url"] = self.path
		dictionary["post-status"] = self.isDraft ? "draft" : "published"

		microblogDictionary["is_conversation"] = self.hasConversation

		if let date = self.publishedDate {
			let dateString = date.uuFormat("yyyy-MM-dd'T'HH:mm:ssZ")
			properties["published"] = dateString
			dictionary["date_published"] = dateString
		}

		dictionary["_microblog"] = microblogDictionary
		dictionary["properties"] = properties

		let authorDictionary = self.owner.dictionary()
		dictionary["author"] = authorDictionary
		
		return dictionary
	}
}
