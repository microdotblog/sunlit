//
//  SnippetsUser.swift
//  SnippetsFramework
//
//  Created by Jonathan Hays on 10/24/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#if os(macOS)
import AppKit
import UUSwift
public typealias SnippetsImage = NSImage
#else
import UIKit
import UUSwift
public typealias SnippetsImage = UIImage
#endif


open class SnippetsUser : NSObject
{
	public convenience init(_ dictionary : [String : Any])
	{
		self.init()
		self.loadFromDictionary(dictionary)
	}
	
	@objc public var fullName = ""
	@objc public var userHandle = ""
	@objc public var pathToUserImage = ""
	@objc public var pathToWebSite = ""
	@objc public var bio = ""
	@objc public var followingCount : Int = 0
	@objc public var discoverCount : Int = 0
	@objc public var isFollowing = false
	@objc public var userImage : SnippetsImage? = nil

	private var avatarDownloadHttpSession : UUHttpRequest?
}


extension SnippetsUser {
	

	@objc public func loadUserImage(completion: @escaping()-> ())
	{
		if let imageData = UUDataCache.shared.data(for: self.pathToUserImage)
		{
			if let image = SnippetsImage(data: imageData)
			{
				self.userImage = image
				completion()
				return
			}
		}

		if self.avatarDownloadHttpSession == nil {
			// If we have gotten here, then there is no image available to display so we need to fetch it...
			let request = UUHttpRequest(url: self.pathToUserImage)
			self.avatarDownloadHttpSession = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
				if let image = parsedServerResponse.parsedResponse as? SnippetsImage
				{
					if let imageData = image.uuPngData()
					{
						UUDataCache.shared.set(data: imageData, for: self.pathToUserImage)
						self.userImage = image
						completion()
					}
				}
			})
		}
	}
	
	func loadFromMicroblogDictionary(_ snippetsDictionary : [String : Any])
	{
		if let userName = snippetsDictionary["username"] as? String
		{
			self.userHandle = userName
		}
		if let bio = snippetsDictionary["bio"] as? String
		{
			self.bio = bio
		}
		if let followingCount = snippetsDictionary["following_count"] as? Int
		{
			self.followingCount = followingCount
		}
		if let discoverCount = snippetsDictionary["discover_count"] as? Int
		{
			self.discoverCount = discoverCount
		}
		if let isFollowing = snippetsDictionary["is_following"] as? Int
		{
			self.isFollowing = (isFollowing > 0)
		}
	}
	
	func loadFromDictionary(_ authorDictionary : [String : Any])
	{
		if let userName = authorDictionary["username"] as? String
		{
			self.userHandle = userName
		}
		
		if let bio = authorDictionary["bio"] as? String
		{
			self.bio = bio
		}
		
		if let snippetsDictionary = authorDictionary["_microblog"] as? [String : Any]
		{
			self.loadFromMicroblogDictionary(snippetsDictionary)
		}
			
		if let fullName = authorDictionary["name"] as? String
		{
			self.fullName = fullName
		}
		
		if let fullName = authorDictionary["full_name"] as? String
		{
			self.fullName = fullName
		}
		
		if let userImagePath = authorDictionary["avatar"] as? String {
			self.pathToUserImage = userImagePath
		}
		else if let userImagePath = authorDictionary["gravatar_url"] as? String {
			self.pathToUserImage = userImagePath
		}
		if let site = authorDictionary["url"] as? String {
			self.pathToWebSite = site
		}
		
		if self.pathToWebSite.count <=  0 {
			if let site = authorDictionary["default_site"] as? String{
				self.pathToWebSite = site
			}
		}
	}
}
