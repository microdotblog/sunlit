//
//  SunlitUser.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/12/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

extension SnippetsUser {
	
	
	
	static func saveAsCurrent(_ user : SnippetsUser) {
		
	}
	
	func attributedTextBio(font : UIFont = UIFont.systemFont(ofSize: 14.0), textColor : UIColor = UIColor.label) -> NSAttributedString {
		
		var attributedBio : NSAttributedString = NSAttributedString(string: self.bio)
		let formattedBio = SunlitPost.addTextStyle(string: self.bio, font: font, textColor: textColor)
		let htmlData = formattedBio.data(using: .utf16)!
		if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
			attributedBio = attributedString
		}

		return attributedBio
	}
	
	static func save(_ user : SnippetsUser) {
		var dictionary : [String : Any] = [:]
		dictionary["full_name"] = user.fullName
		dictionary["user_handle"] = user.userHandle
		dictionary["path_to_user_image"] = user.pathToUserImage
		dictionary["path_to_web_site"] = user.pathToWebSite
		dictionary["bio"] = user.bio
		dictionary["following_count"] = user.followingCount
		dictionary["discover_count"] = user.discoverCount
		dictionary["is_following"] = user.isFollowing
		
		UserDefaults.standard.set(dictionary, forKey: user.userHandle)
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
