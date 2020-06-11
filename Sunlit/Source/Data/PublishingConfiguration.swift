//
//  PublishingConfiguration.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation
import Snippets


class PublishingConfiguration {
	
	static var current : PublishingConfiguration {
		get {
			let config = PublishingConfiguration()
			return config
		}
	}
	
	
	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	
	static func configureSnippetsBlog(_ dictionary : [String : Any], mediaEndpoint : String? = nil) {
		Settings.setInsecureDictionary(dictionary, forKey: PublishingConfiguration.snippetsConfigurationKey)
		
		if let mediaEndpoint = mediaEndpoint {
			PublishingConfiguration.configureMicropubMediaEndpoint(mediaEndpoint)
		}
	}
	
	static func configureXMLRPCBlog(username: String, password: String, url : String, endpoint : String, blogId : String, app : String) {
		Settings.setInsecureString(username, forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
		Settings.setInsecureString(url, forKey: PublishingConfiguration.xmlRPCBlogURLKey)
		Settings.setInsecureString(endpoint, forKey: PublishingConfiguration.xmlRPCBlogEndpointKey)
		Settings.setInsecureString(blogId, forKey: PublishingConfiguration.xmlRPCBlogIDKey)
		Settings.setInsecureString(app, forKey: PublishingConfiguration.xmlRPCBlogAppKey)
		Settings.setSecureString(password, forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
	}
	
	static func configureMicropubBlog(username : String, endpoint : String, mediaEndpoint : String? = nil) {
		Settings.setInsecureString(username, forKey: PublishingConfiguration.micropubUserKey)
		Settings.setInsecureString(endpoint, forKey: PublishingConfiguration.micropubPostingEndpointKey)
		if let mediaPath = mediaEndpoint {
			Settings.setInsecureString(mediaPath, forKey: PublishingConfiguration.micropubMediaEndpointKey)
		}
		else {
			Settings.setInsecureString(endpoint, forKey: PublishingConfiguration.micropubMediaEndpointKey)
		}
	}
	
	static func configureMicropubMediaEndpoint(_ mediaEndpoint : String) {
		Settings.setInsecureString(mediaEndpoint, forKey: PublishingConfiguration.micropubMediaEndpointKey)
	}
	
	static func deleteXMLRPCBlogSettings() {
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogURLKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogEndpointKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogIDKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogAppKey)
		Settings.deleteSecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
	}
	
	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func hasConfigurationForExternal() -> Bool {
		if Settings.getSecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey) != nil &&
			Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey).count > 0 &&
			Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogEndpointKey).count > 0 {
			return true
		}
		
		return false
	}
	
	func getBlogName() -> String {
		return self.username
	}
	
	func getBlogAddress() -> String {
		return self.address
	}
	
	func getMediaEndpoint() -> String {
		return self.mediaEndpoint
	}
	
	func getPostingEndpoint() -> String {
		return self.postingEndpoint
	}
	
	func getBlogIdentifier() -> String {
		return self.blogId
	}
	
	func xmlRPCIdentity() -> SnippetsXMLRPCIdentity? {
		let wordPress = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogAppKey) == "WordPress"

		if let password = Settings.getSecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey) {
			let identity = SnippetsXMLRPCIdentity.create(username: self.username, password: password, endpoint: self.postingEndpoint, blogId: self.blogId, wordPress: wordPress)
			return identity
		}
		
		return nil
	}
	
	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	private init () {
		if Settings.usesExternalBlog() {
			isXMLRPC = true
			
			self.username = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
			self.address = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogURLKey)
			self.postingEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogEndpointKey)
			self.blogId = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogIDKey)
		}
		else {
			isXMLRPC = false
			
			self.username = Settings.getInsecureString(forKey: PublishingConfiguration.micropubUserKey)			
			self.address = self.selectedBlogName() ?? ""
			self.mediaEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubMediaEndpointKey)
			self.postingEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubPostingEndpointKey)
			self.blogId = self.selectedBlogIdentifier() ?? ""
		}
	}

	private func selectedBlogIdentifier() -> String? {
		if let dictionary =  Settings.getInsecureDictionary(forKey: PublishingConfiguration.snippetsConfigurationKey) {
			return dictionary["uid"] as? String
		}
		
		return nil
	}
	
	private func selectedBlogName() -> String? {
		if let dictionary =  Settings.getInsecureDictionary(forKey: PublishingConfiguration.snippetsConfigurationKey) {
			return dictionary["name"] as? String
		}
		
		return nil
	}


	
	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	private var isXMLRPC = false
	private var address = ""
	private var username = ""
	
	private var mediaEndpoint = ""
	private var postingEndpoint = ""
	private var blogId = ""


	
	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	private static let xmlRPCBlogUsernameKey = "ExternalBlogUsername"
	private static let xmlRPCBlogURLKey = "ExternalBlogURL"
	private static let xmlRPCBlogEndpointKey = "ExternalBlogEndpoint"
	private static let xmlRPCBlogIDKey = "ExternalBlogID"
	private static let xmlRPCBlogAppKey = "ExternalBlogApp"
	
	private static let micropubPostingEndpointKey = "ExternalMicropubPostingEndpoint"
	private static let micropubMediaEndpointKey = "ExternalMicropubMediaEndpoint"
	private static let micropubUserKey = "ExternalMicropubMe"
	
	private static let snippetsConfigurationKey = "SunlitBlogDictionary"
}
