//
//  SunlitUser.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/12/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Snippets

extension SnippetsUser {
	
	func attributedTextBio(font : UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body), textColor : UIColor = UIColor.label) -> NSAttributedString {
		let formattedBio = SunlitPost.addTextStyle(string: self.bio, font: font, textColor: textColor)
		return NSAttributedString(string: formattedBio).html()
	}
	
	var posts : [SnippetsPost] {
		get {
			var postArray : [SnippetsPost] = []
			if let array = Settings.object(forKey: self.username + "-Posts") as? [[String : Any]] {
				for dictionary in array {
					let post = SnippetsPost(dictionary)
					postArray.append(post)
				}
			}
			return postArray
		}
		set(posts) {
			var dictionaryArray : [[String : Any]] = []
			for post in posts {
				let dictionary = post.dictionary()
				dictionaryArray.append(dictionary)
			}
			
            Settings.setValue(dictionaryArray, forKey: self.username + "-Posts")
		}
	}
	
	func dictionary(mergeWith: [String : Any]? = nil) -> [String : Any] {
		
		var dictionary : [String : Any] = [:]
		if let mergeDictionary = mergeWith {
			dictionary = mergeDictionary
		}
						
		if self.fullName.count > 0 {
			dictionary["full_name"] = self.fullName
		}
		
		if self.username.count > 0 {
			dictionary["user_handle"] = self.username
		}
			
		if self.avatarURL.count > 0 {
			dictionary["path_to_user_image"] = self.avatarURL
		}
			
		if self.siteURL.count > 0 {
			dictionary["path_to_web_site"] = self.siteURL
		}
			
		if self.bio.count > 0 {
			dictionary["bio"] = self.bio
		}
			
		if self.followingCount > 0 {
			dictionary["following_count"] = self.followingCount
		}
			
		if self.discoverCount > 0 {
			dictionary["discover_count"] = self.discoverCount
		}
			
		dictionary["is_following"] = self.isFollowing
		
		return dictionary
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
            Snippets.Microblog.fetchCurrentUserInfo { (error, user) in
				if let current = user {
					_ = SnippetsUser.saveAsCurrent(current)
				}
				
				completion(user)
			}
		}
	}
	
	static func deleteCurrentUser() {
        Settings.removeObject(forKey: "Current User")
	}
	
	static func save(_ user : SnippetsUser, key : String? = nil) -> SnippetsUser {
		
		var saveKey = user.username
		if let k = key {
			saveKey = k
		}
		
		// See if there is an existing dictionary to see if we need to merge...
		let master = Settings.object(forKey: saveKey) as? [String : Any]
		let dictionary = user.dictionary(mergeWith: master)
		
        Settings.setValue(dictionary, forKey: saveKey)
		
		return SnippetsUser.load(saveKey)!
	}
	
	static func load(_ userHandle : String) -> SnippetsUser? {
		
		if let dictionary = Settings.object(forKey: userHandle) as? [String : Any] {
			let user = SnippetsUser()
			user.fullName = dictionary["full_name"] as? String ?? ""
			user.username = dictionary["user_handle"] as? String ?? ""
			user.avatarURL = dictionary["path_to_user_image"] as? String ?? ""
			user.siteURL = dictionary["path_to_web_site"] as? String ?? ""
			user.bio = dictionary["bio"] as? String ?? ""
			user.followingCount = dictionary["following_count"] as? Int ?? 0
			user.discoverCount = dictionary["discover_count"] as? Int ?? 0
			user.isFollowing = dictionary["is_following"] as? Bool ?? false
			
			return user
		}
		
		return nil
	}
}

