//
//  BlogSettings.swift
//  Sunlit
//
//  Created by Jonathan Hays on 6/10/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation
import Snippets

class BlogSettings : NSObject {
        
    static func publishedBlogs() -> [BlogSettings] {
        
        var blogList : [BlogSettings] = []
        
        if let list = UserDefaults.standard.object(forKey: BlogSettings.listOfPublishingBlogsKey) as? [String] {
            for blogAddress in list {
                let blogInfo = BlogSettings(blogAddress)
                blogList.append(blogInfo)
            }
        }
        
        if blogList.isEmpty {
            blogList.append(BlogSettings.defaultBlogInfo)
        }
        
        return blogList
    }
    
    static func addPublishedBlog(_ settings : BlogSettings) {
        
        let blogAddress = settings.blogAddress
        
        var publishedList : [String] = []
        
        if let list = UserDefaults.standard.object(forKey: BlogSettings.listOfPublishingBlogsKey) as? [String] {
            publishedList = list
        }
        
        if !publishedList.contains(blogAddress) {
            publishedList.append(blogAddress)
            UserDefaults.standard.setValue(publishedList, forKey: BlogSettings.listOfPublishingBlogsKey)
        }
        
        settings.save()
    }
    
    static var publishingPath : String {
        get {
            if let path = UserDefaults.standard.object(forKey: BlogSettings.savedPublishingKey) as? String {
                return path
            }
            
            return "https://micro.blog"
        }
        
        set (path) {
            UserDefaults.standard.setValue(path, forKey: BlogSettings.savedPublishingKey)
        }
    }
    
    static var timelinePath : String {
        get {
            if let path = UserDefaults.standard.object(forKey: BlogSettings.savedTimelineKey) as? String {
                return path
            }
            
            return "https://micro.blog"
        }
        set (path) {
            UserDefaults.standard.setValue(path, forKey: BlogSettings.savedTimelineKey)
        }
    }

    
    static var defaultBlogInfo : BlogSettings {
        get {
            var dictionary : [String : Any] = [:]
            dictionary["tokenEndpoint"] = "https://micro.blog"
            dictionary["blogAddress"] = "https://micro.blog"
            dictionary["blogName"] = "Micro.blog"
            dictionary["Snippets.Configuration"] = Snippets.Configuration.microblogConfiguration(token: "").toDictionary()
            
            return BlogSettings(dictionary)
        }
    }
    
    static func deleteTimelineInfo() {
        UserDefaults.standard.removeObject(forKey: BlogSettings.savedTimelineKey)
    }
    
    static func deletePublishingInfo() {
        UserDefaults.standard.removeObject(forKey: BlogSettings.savedPublishingKey)
    }
    
    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    MARK: - Construction interface
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
    
    init(_ path : String) {
        super.init()
        
        self.load(path)
    }

    private init(_ dictionary : [String : Any]) {
        super.init()
        
        self.dictionary = dictionary
    }

    
    func load(_ blogAddress : String) {
        if let dictionary = UserDefaults.standard.object(forKey: BlogSettings.publishingSettingsKey + blogAddress) as? [String : Any] {
            self.dictionary = dictionary
        }
        else {
            self.dictionary = BlogSettings.defaultBlogInfo.dictionary
            self.blogAddress = blogAddress
        }
    }
    
    func save() {
        let blogAddress = self.blogAddress
        UserDefaults.standard.setValue(self.dictionary, forKey: BlogSettings.publishingSettingsKey + blogAddress)
    }

    
    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    MARK: - Getter/Setters
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    var snippetsConfiguration : Snippets.Configuration? {
        get {
            if let configuration = self.dictionary["Snippets.Configuration"] as? [String : Any] {
                let snippetsConfig = Snippets.Configuration.fromDictionary(configuration)
                return snippetsConfig
            }
            
            return nil
        }
        set (configuration) {
            if let config = configuration {
                let dictionary = config.toDictionary()
                self.dictionary["Snippets.Configuration"] = dictionary
            }
            else {
                self.dictionary.removeValue(forKey: "Snippets.Configuration")
            }
            
            self.save()
        }
    }
    
    var microblogToken : String {
        get {
            if let token = self.dictionary["microblogToken"] as? String {
                return token
            }
            
            return ""
        }
        set (token) {
            self.dictionary["microblogToken"] = token
            self.save()
        }
    }
    
    var username : String {
        get {
            if let name = self.dictionary["username"] as? String {
                return name
            }
            
            return ""
        }
        set (name) {
            self.dictionary["username"] = name
            self.save()
        }
    }
    
    var tokenEndpoint : String {
        get {
            if let endpoint = self.dictionary["tokenEndpoint"] as? String {
                return endpoint
            }
            return ""
        }
        set (endpoint) {
            self.dictionary["tokenEndpoint"] = endpoint
            self.save()
        }
    }

    var authEndpoint : String {
        get {
            if let endpoint = self.dictionary["authEndpoint"] as? String {
                return endpoint
            }
            return ""
        }
        set (endpoint) {
            self.dictionary["authEndpoint"] = endpoint
            self.save()
        }
    }

    
    var stateKey : String {
        get {
            if let state = self.dictionary["stateKey"] as? String {
                return state
            }
            return ""
        }
        
        set (state) {
            self.dictionary["stateKey"] = state
            self.save()
        }
    }
    
    var blogName : String {
        get {
            if let name = self.dictionary["blogName"] as? String {
                return name
            }
            
            return ""
        }
        set (name) {
            self.dictionary["blogName"] = name
            self.save()
        }
    }
    
    var blogAddress : String {
        get {
            if let name = self.dictionary["blogAddress"] as? String {
                return name
            }
            
            return ""
        }
        set (name) {
            self.dictionary["blogAddress"] = name
            self.save()
        }
    }

	static func migrate() {

		// One time migration
		if UserDefaults.standard.bool(forKey: "3.0 to 3.1 settings migration") {
			return
		}

		UserDefaults.standard.setValue(true, forKey: "3.0 to 3.1 settings migration")

		let usesExternalBlog = UserDefaults.standard.bool(forKey: externalBlogPreferenceKey)

		migrateXMLRPCSettings(usesExternalBlog: usesExternalBlog)
		migrateMicropubSettings(usesExternalBlog: usesExternalBlog)
		migrateMicroblogSettings(usesExternalBlog: usesExternalBlog)
	}

	static func migrateMicroblogSettings(usesExternalBlog : Bool) {

		if let permanentToken = Settings.snippetsToken() {
			Snippets.Configuration.timeline.micropubToken = permanentToken
		}

		var selectedUid = ""
		if let dictionary =  Settings.getInsecureDictionary(forKey: snippetsConfigurationKey) {
			selectedUid = dictionary["uid"] as? String ?? ""
		}

		Snippets.Microblog.fetchCurrentUserConfiguration { (error, configuration) in

			// Check for a media endpoint definition...
			let mediaEndPoint : String = configuration["media-endpoint"] as? String ?? ""
			let micropubEndPoint = Snippets.Configuration.timeline.micropubEndpoint
			let micropubToken = Snippets.Configuration.timeline.micropubToken


			if let destinations = configuration["destination"] as? [[String : Any]] {

				for destination in destinations {
					if let title = destination["name"] as? String,
					   let blogId = destination["uid"] as? String {

						let config = Snippets.Configuration.fromDictionary(destination)
						config.micropubUid = blogId
						config.micropubEndpoint = micropubEndPoint
						config.micropubMediaEndpoint = mediaEndPoint
						config.micropubToken = micropubToken

						let blogSettings = BlogSettings(title)
						blogSettings.blogName = title
						blogSettings.snippetsConfiguration = config
						blogSettings.save()

						BlogSettings.addPublishedBlog(blogSettings)
					}
				}

				if !usesExternalBlog {
					selectedUid = selectedUid.replacingOccurrences(of: "https://", with: "")
					selectedUid = selectedUid.replacingOccurrences(of: "/", with: "")
					BlogSettings.publishingPath = selectedUid
				}
			}
		}
	}

	static func migrateXMLRPCSettings(usesExternalBlog : Bool) {

		let xmlUserName = UserDefaults.standard.object(forKey: xmlRPCBlogUsernameKey) as? String
		let xmlPassword = Settings.getSecureString(forKey: xmlRPCBlogUsernameKey)
		let xmlUrl = UserDefaults.standard.object(forKey: xmlRPCBlogURLKey) as? String
		let xmlEndpoint = UserDefaults.standard.object(forKey: xmlRPCBlogEndpointKey) as? String
		let xmlBlogId = UserDefaults.standard.object(forKey: xmlRPCBlogIDKey) as? String
		let wordPress = Settings.getInsecureString(forKey: xmlRPCBlogAppKey) ==  "WordPress"

		if let name = xmlUserName,
		   let password = xmlPassword,
		   let url = xmlUrl,
		   let endpoint = xmlEndpoint,
		   let blogId = xmlBlogId {

			let blogSettings = BlogSettings(url)
			blogSettings.blogAddress = url
			blogSettings.username = name

			var identity = Snippets.Configuration.xmlRpcConfiguration(username: name, password: password, endpoint: endpoint, blogId: blogId)
			if wordPress {
				identity = Snippets.Configuration.wordpressConfiguration(username: name, password: password, endpoint: endpoint, blogId: blogId)
			}

			blogSettings.snippetsConfiguration = identity

			BlogSettings.addPublishedBlog(blogSettings)

			if usesExternalBlog {
				BlogSettings.publishingPath = url
			}
		}
	}

	static func migrateMicropubSettings(usesExternalBlog : Bool) {
		let micropubToken = Settings.getSecureString(forKey: micropubAccessTokenKey)
		let micropubMediaEndpoint = UserDefaults.standard.object(forKey: micropubMediaEndpointKey) as? String
		let micropubPostingEndpoint = UserDefaults.standard.object(forKey: micropubUserKey) as? String
		//let micropubState = UserDefaults.standard.object(forKey: micropubStateKey) as? String
		let micropubUser = UserDefaults.standard.object(forKey: micropubUserKey) as? String

		if let user = micropubUser,
		   let token = micropubToken,
		   let endpoint = micropubPostingEndpoint {

			let config = Snippets.Configuration.micropubConfiguration(token: token, endpoint: endpoint)
			config.micropubMediaEndpoint = micropubMediaEndpoint ?? ""

			let settings = BlogSettings(user)
			settings.microblogToken = token
			settings.snippetsConfiguration = config
			settings.save()
			BlogSettings.addPublishedBlog(settings)

			if usesExternalBlog {
				BlogSettings.publishingPath = user
			}
		}
	}

    var dictionary : [String : Any] = [:]

    
    private static let listOfPublishingBlogsKey = "SunlitListOfPublishingBlogsKey"
    private static let savedTimelineKey = "SunlitTimelineKey"
    private static let savedPublishingKey = "SunlitPublishingKey"
    private static let publishingSettingsKey = "SunlitServerConfiguration."


	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: - Legacy keys...
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

	private static let externalBlogPreferenceKey = "ExternalBlogIsPreferred"
}


