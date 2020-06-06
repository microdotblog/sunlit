//
//  SnippetsPost.swift
//  SnippetsFramework
//
//  Created by Jonathan Hays on 10/24/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#if os(macOS)
import AppKit
import UUSwift
#else
import UIKit
import UUSwift
#endif


open class SnippetsPost : NSObject
{
	public convenience init(_ dictionary : [String : Any])
	{
		self.init()
		self.loadFromDictionary(dictionary)
	}
	
	@objc public var identifier = ""
	@objc public var owner = SnippetsUser()
	@objc public var htmlText = ""
	@objc public var path = ""
	@objc public var publishedDate : Date?
	@objc public var hasConversation : Bool = false
	@objc public var replies : [SnippetsPost] = []
	@objc public var isDraft : Bool = false
}


extension SnippetsPost {

	func loadFromDictionary(_ sourceDictionary : [String : Any])
	{
		var dictionary = sourceDictionary
		
		// Test to see if we have the micropub version of this dictionary
		if let properties = dictionary["properties"] as? [String : Any] {
			
			dictionary = properties
			
			if let urlArray = dictionary["url"] as? [String]{
				self.path = urlArray[0]
			}
			
			if let contentArray = dictionary["content"] as? [String] {
				self.htmlText = contentArray[0]
			}
			
			if let publishedArray = dictionary["published"] as? [String] {
				let dateString = publishedArray[0]
				
				self.publishedDate = dateString.uuParseDate(format: "yyyy-MM-dd'T'HH:mm:ssZ")
			}
			
			if let draftStatusArray = dictionary["post-status"] as? [String] {
				let draftStatus = draftStatusArray[0]
				self.isDraft = (draftStatus == "draft")
			}
			
		}
		
		if let microblogDictionary = dictionary["_microblog"] as? [String : Any] {
			if let conversation = microblogDictionary["is_conversation"] as? NSNumber {
				self.hasConversation = conversation.intValue > 0
			}
		}
		
		if let identifier = dictionary["id"] as? String
		{
			self.identifier = identifier
		}
		
		if let postText = dictionary["content_html"] as? String
		{
			self.htmlText = postText
		}

		if let authorDictionary = dictionary["author"] as? [String : Any]
		{
			self.owner.loadFromDictionary(authorDictionary)
		}

		if let path = dictionary["url"] as? String
		{
			self.path = path
		}
		
		if let dateString = dictionary["date_published"] as? String
		{
			self.publishedDate = dateString.uuParseDate(format: "yyyy-MM-dd'T'HH:mm:ssZ")
		}
		
		if let draftStatus = dictionary["post-status"] as? String
		{
			self.isDraft = (draftStatus == "draft")
		}
	}
}
