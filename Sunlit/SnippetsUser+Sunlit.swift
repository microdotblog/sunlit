//
//  SunlitUser.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/12/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

extension SnippetsUser {
	
	func attributedTextBio(font : UIFont = UIFont.systemFont(ofSize: 14.0), textColor : UIColor = UIColor.label) -> NSAttributedString {
		
		var attributedBio : NSAttributedString = NSAttributedString(string: self.bio)
		let formattedBio = SunlitPost.addTextStyle(string: self.bio, font: font, textColor: textColor)
		let htmlData = formattedBio.data(using: .utf16)!
		if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
			attributedBio = attributedString
		}

		return attributedBio
	}
	
	
	/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
	
	// saveAsCurrent and save both merge the user with any extended attributes that have already been stored...
	static func saveAsCurrent(_ user : SnippetsUser) -> SnippetsUser {
		return SnippetsUser.save(user, key: "Current User")
	}
	
	static func current() -> SnippetsUser? {
		return SnippetsUser.load("Current User")
	}
	
	static func fetchCurrent(_ completion : @escaping (SnippetsUser?) -> Void) {
		if let user = SnippetsUser.current() {
			completion(user)
		}
		else {
			Snippets.shared.fetchCurrentUserInfo { (error, user) in
				if let current = user {
					_ = SnippetsUser.saveAsCurrent(current)
				}
				
				completion(user)
			}
		}
	}
	
	static func save(_ user : SnippetsUser, key : String? = nil) -> SnippetsUser {
		
		var saveKey = user.userHandle
		if let k = key {
			saveKey = k
		}
		
		var dictionary : [String : Any] = [:]
		
		// See if there is an existing dictionary to see if we need to merge...
		if let master = UserDefaults.standard.object(forKey: saveKey) as? [String : Any] {
			dictionary = master
		}
		
		if user.fullName.count > 0 {
			dictionary["full_name"] = user.fullName
		}
	
		if user.userHandle.count > 0 {
			dictionary["user_handle"] = user.userHandle
		}
		
		if user.pathToUserImage.count > 0 {
			dictionary["path_to_user_image"] = user.pathToUserImage
		}
		
		if user.pathToWebSite.count > 0 {
			dictionary["path_to_web_site"] = user.pathToWebSite
		}
		
		if user.bio.count > 0 {
			dictionary["bio"] = user.bio
		}
		
		if user.followingCount > 0 {
			dictionary["following_count"] = user.followingCount
		}
		
		if user.discoverCount > 0 {
			dictionary["discover_count"] = user.discoverCount
		}
		
		if user.isFollowing {
			dictionary["is_following"] = user.isFollowing
		}
		
		UserDefaults.standard.set(dictionary, forKey: saveKey)
		
		return SnippetsUser.load(saveKey)!
	}
	
	static func load(_ userHandle : String) -> SnippetsUser? {
		
		if let dictionary = UserDefaults.standard.object(forKey: userHandle) as? [String : Any] {
			let user = SnippetsUser()
			user.fullName = dictionary["full_name"] as? String ?? ""
			user.userHandle = dictionary["user_handle"] as? String ?? ""
			user.pathToUserImage = dictionary["path_to_user_image"] as? String ?? ""
			user.pathToWebSite = dictionary["path_to_web_site"] as? String ?? ""
			user.bio = dictionary["bio"] as? String ?? ""
			user.followingCount = dictionary["following_count"] as? Int ?? 0
			user.discoverCount = dictionary["discover_count"] as? Int ?? 0
			user.isFollowing = dictionary["is_following"] as? Bool ?? false
			
			return user
		}
		
		return nil
	}
}
