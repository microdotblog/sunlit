//
//  Settings.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

class Settings {
	
	static func savePermanentToken(_ token : String) {
		//UUKeychain.saveString(key: "SunlitToken", acceessLevel: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, string: token)
		UserDefaults.standard.setValue(token, forKey: "SunlitToken")
	}

	static func permanentToken() -> String? {
		//return UUKeychain.getString(key: "SunlitToken")
		return UserDefaults.standard.string(forKey: "SunlitToken")
	}
	
	static func deletePermanentToken() {
		UserDefaults.standard.removeObject(forKey: "SunlitToken")
	}
	
	static func selectedBlogIdentifier() -> String? {
		if let dictionary = Settings.blogDictionary() {
			return dictionary["uid"] as? String
		}
		
		return nil
	}

	static func selectedBlogName() -> String? {
		if let dictionary = Settings.blogDictionary() {
			return dictionary["name"] as? String
		}
		
		return nil
	}
	
	static func saveBlogDictionary(_ dictionary : [String : Any]) {
		UserDefaults.standard.setValue(dictionary, forKey: "SunlitBlogDictionary")
	}
	
	static func blogDictionary() -> [String : Any]? {
		return UserDefaults.standard.object(forKey: "SunlitBlogDictionary") as? [String : Any]
	}
	
	static func saveMediaEndpoint(_ mediaEndpoint : String) {
		UserDefaults.standard.setValue(mediaEndpoint, forKey: "SunlitMediaEndpoint")
	}
	
	static func mediaEndpoint() -> String? {
		return UserDefaults.standard.string(forKey: "SunlitMediaEndpoint")
	}

}
