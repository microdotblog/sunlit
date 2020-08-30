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
			self.updateSnippetsConfig()
		}
	}
	
	static func configureXMLRPCBlog(username: String, password: String, url : String, endpoint : String, blogId : String, app : String) {
		Settings.setInsecureString(username, forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
		Settings.setInsecureString(url, forKey: PublishingConfiguration.xmlRPCBlogURLKey)
		Settings.setInsecureString(endpoint, forKey: PublishingConfiguration.xmlRPCBlogEndpointKey)
		Settings.setInsecureString(blogId, forKey: PublishingConfiguration.xmlRPCBlogIDKey)
		Settings.setInsecureString(app, forKey: PublishingConfiguration.xmlRPCBlogAppKey)
		Settings.setSecureString(password, forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)

		self.updateSnippetsConfig()
	}
	
	static func configureMicropubBlog(username : String, postingEndpoint : String, authEndpoint : String, tokenEndpoint : String, stateKey : String, mediaEndpoint : String? = nil) {
		Settings.setInsecureString(username, forKey: PublishingConfiguration.micropubUserKey)
		Settings.setInsecureString(postingEndpoint, forKey: PublishingConfiguration.micropubPostingEndpointKey)
		Settings.setInsecureString(authEndpoint, forKey: PublishingConfiguration.micropubAuthEndpointKey)
		Settings.setInsecureString(tokenEndpoint, forKey: PublishingConfiguration.micropubTokenEndpointKey)
		Settings.setInsecureString(stateKey, forKey: PublishingConfiguration.micropubStateKey)
		
		if let mediaPath = mediaEndpoint {
			Settings.setInsecureString(mediaPath, forKey: PublishingConfiguration.micropubMediaEndpointKey)
		}
		else {
			Settings.setInsecureString(postingEndpoint, forKey: PublishingConfiguration.micropubMediaEndpointKey)
		}

		self.updateSnippetsConfig()
	}

	static func configureMicropubBlog(accessToken: String) {
		Settings.setSecureString(accessToken, forKey: PublishingConfiguration.micropubAccessTokenKey)
		self.updateSnippetsConfig()
	}
	
	static func configureMicropubMediaEndpoint(_ mediaEndpoint : String) {
		Settings.setInsecureString(mediaEndpoint, forKey: PublishingConfiguration.micropubMediaEndpointKey)
		self.updateSnippetsConfig()
	}
	
	static func deleteXMLRPCBlogSettings() {
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogURLKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogEndpointKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogIDKey)
		Settings.deleteInsecureString(forKey: PublishingConfiguration.xmlRPCBlogAppKey)
		Settings.deleteSecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)

		self.updateSnippetsConfig()
	}

	static func deleteMicropubSettings() {
		Settings.deleteSecureString(forKey: PublishingConfiguration.micropubAccessTokenKey)
		self.updateSnippetsConfig()
	}
	
	static func fetchMicropubStateKey() -> String {
		return Settings.getInsecureString(forKey: PublishingConfiguration.micropubStateKey)
	}
	
	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	func hasConfigurationForExternal() -> Bool {
		if self.hasConfigurationForMicropub() {
			return true
		}
		
		if self.hasConfigurationForXMLRPC() {
			return true
		}
		
		return false
	}
	
	func hasConfigurationForMicropub() -> Bool {
		return Settings.getSecureString(forKey: PublishingConfiguration.micropubAccessTokenKey) != nil
	}
	
	func hasConfigurationForXMLRPC() -> Bool {
		return Settings.getSecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey) != nil &&
			Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey).count > 0 &&
			Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogEndpointKey).count > 0
	}
	
	func getToken() -> String {
		if let token = Settings.getSecureString(forKey: PublishingConfiguration.micropubAccessTokenKey) {
			return token
		}
		else {
			return ""
		}
	}
	
	func getBlogName() -> String {
		return self.username
	}
	
	func getBlogAddress() -> String {
		var s = self.address
		if s.contains("http") {
			if let url = URL(string: s) {
				if let host = url.host {
					s = host
				}
			}
		}
		
		return s
	}
	
	func getMediaEndpoint() -> String {
		return self.mediaEndpoint
	}
	
	func getPostingEndpoint() -> String {
		return self.postingEndpoint
	}

	func getAuthEndpoint() -> String {
		return self.authEndpoint
	}

	func getTokenEndpoint() -> String {
		return self.tokenEndpoint
	}

	func getBlogIdentifier() -> String {
		return self.blogId
	}
	
	func getExternalBlogAppName() -> String {
		let app = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogAppKey)
		return app
	}
	
	func xmlRPCIdentity() -> SnippetsXMLRPCIdentity? {
		let wordPress = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogAppKey) == "WordPress"

		if let password = Settings.getSecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey) {
			let identity = SnippetsXMLRPCIdentity.create(username: self.username, password: password, endpoint: self.postingEndpoint, blogId: self.blogId, wordPress: wordPress)
			return identity
		}
		
		return nil
	}

	static func updateSnippetsConfig() {
		let sunlit_config = self.current
		if Settings.usesExternalBlog() && self.current.hasConfigurationForExternal() {
			let snippets_config = Snippets.Configuration()
			snippets_config.token = sunlit_config.getToken()
			snippets_config.endpoint = sunlit_config.getPostingEndpoint()
			snippets_config.micropubEndpoint = sunlit_config.getPostingEndpoint()
			snippets_config.mediaEndpoint = sunlit_config.getMediaEndpoint()
			snippets_config.uid = sunlit_config.getBlogIdentifier()
			Snippets.shared.configurePublishing(snippets_config)
		}
		else {
			let snippets_config = Snippets.shared.timelineConfiguration
			snippets_config.uid = sunlit_config.getBlogIdentifier()
			Snippets.shared.configurePublishing(snippets_config)
		}
	}

	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	private init () {
		if Settings.usesExternalBlog() {
			self.isExternal = true
			
			if Settings.getSecureString(forKey: PublishingConfiguration.micropubAccessTokenKey) != nil {
				self.username = Settings.getInsecureString(forKey: PublishingConfiguration.micropubUserKey)
				self.address = Settings.getInsecureString(forKey: PublishingConfiguration.micropubUserKey)
				self.postingEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubPostingEndpointKey)
				self.mediaEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubMediaEndpointKey)
				self.blogId = ""
			}
			else {
				self.username = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogUsernameKey)
				self.address = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogURLKey)
				self.postingEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogEndpointKey)
				self.blogId = Settings.getInsecureString(forKey: PublishingConfiguration.xmlRPCBlogIDKey)
			}
		}
		else {
			self.isExternal = false
			
			self.username = Settings.getInsecureString(forKey: PublishingConfiguration.micropubUserKey)			
			self.address = self.selectedBlogName() ?? ""
			self.mediaEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubMediaEndpointKey)
			self.postingEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubPostingEndpointKey)
			self.authEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubAuthEndpointKey)
			self.tokenEndpoint = Settings.getInsecureString(forKey: PublishingConfiguration.micropubTokenEndpointKey)
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
	
	private var isExternal = false
	private var address = ""
	private var username = ""
	
	private var mediaEndpoint = ""
	private var postingEndpoint = ""
	private var authEndpoint = ""
	private var tokenEndpoint = ""
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
	private static let micropubAuthEndpointKey = "ExternalMicropubAuthEndpoint"
	private static let micropubTokenEndpointKey = "ExternalMicropubTokenEndpoint"
	private static let micropubMediaEndpointKey = "ExternalMicropubMediaEndpoint"
	private static let micropubUserKey = "ExternalMicropubMe"
	private static let micropubStateKey = "ExternalMicropubState"
	private static let micropubAccessTokenKey = "ExternalMicropubAccessToken"

	private static let snippetsConfigurationKey = "SunlitBlogDictionary"
}
