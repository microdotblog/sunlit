//
//  Settings.swift
//  Sunlit
//
//  Created by Jonathan Hays on 5/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit
import Security
import Snippets
import UUSwiftCore

class Settings {

	static private let shared = UserDefaults(suiteName: "group.blog.micro.sunlit") ?? .standard
	static private let snippetsKeychainService = "blog.micro.sunlit.account"
	static private let snippetsKeychainAccount = "Snippets"
	static private let pendingSnippetsSignInDateKey = "Pending Micro.blog Sign In Date"
	static private let pendingSnippetsSignInLifetime: TimeInterval = 15.0 * 60.0
	static private let legacySnippetsKeychainServices = [
		"blog.micro.sunlit-UUKeychain",
		"blog.micro.sunlit.sharing-UUKeychain",
		"blog.micro.sunlit.widget-UUKeychain"
	]
	static private(set) var accountGeneration = 0

	static var isSignedIn: Bool {
		return self.snippetsToken() != nil && SnippetsUser.current() != nil
	}

    static func bool(forKey key: String) -> Bool {
        return self.object(forKey: key) as? Bool ?? false
    }

    static func object(forKey key : String) -> Any? {
        if let object = Settings.shared.object(forKey: key) {
            return object
        }

        if let object = UserDefaults.standard.object(forKey: key) {
            Settings.shared.setValue(object, forKey: key)
            return object
        }

        return nil
    }

    static func removeObject(forKey key : String) {
        Settings.shared.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    static func setValue(_ object : Any?, forKey key : String) {
        Settings.shared.setValue(object, forKey: key)
    }

	static func getInsecureString(forKey key : String) -> String {
        if let value = Settings.shared.string(forKey: key) {
            return value
        }

        if let value = UserDefaults.standard.string(forKey: key) {
            // If we got here, it means we need to migrate the key to the shared keychain...
            Settings.shared.setValue(value, forKey: key)
            return value
        }

        return ""
	}
	
	static func setInsecureString(_ value : String, forKey key : String) {
        Settings.shared.setValue(value, forKey: key)
	}
	
	static func deleteInsecureString(forKey key : String) {
        Settings.shared.removeObject(forKey: key)
		UserDefaults.standard.removeObject(forKey: key)
	}
	
	static func getInsecureDictionary(forKey key : String) -> [String : Any]? {
        if let dictionary = Settings.shared.object(forKey: key) as? [String : Any] {
            return dictionary
        }

        if let dictionary = UserDefaults.standard.object(forKey: key) as? [String : Any] {
            // If we got here, it means there is a setting to migrate...
            Settings.shared.set(dictionary, forKey: key)
            return dictionary
        }

        return nil
	}
	
	static func setInsecureDictionary(_ dictionary : [String : Any], forKey : String) {
		Settings.shared.set(dictionary, forKey: forKey)
	}
	
	static func setSecureString(_ value : String, forKey : String) {
		UUKeychain.saveString(key: forKey, acceessLevel: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, string: value)
	}
	
	static func getSecureString(forKey : String) -> String? {
		return UUKeychain.getString(key: forKey)
	}
	
	static func deleteSecureString(forKey : String) {
		UUKeychain.remove(key: forKey)
	}
	
	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	MARK: -
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

	
	static func logout() {
		accountGeneration += 1

		BlogSettings.deleteAllAccountInfo()
		Settings.deleteSnippetsToken()
		SnippetsUser.deleteCurrentUser()

		let preservedKeys = Set([
			Settings.oneTimeImportKey,
			"3.0 to 3.1 settings migration"
		])
		let accountKeys = Settings.shared.dictionaryRepresentation().keys.filter { key in
			!preservedKeys.contains(key) && !key.hasPrefix("CacheClearKey-")
		}
		for key in accountKeys {
			Settings.removeObject(forKey: key)
		}

		// Keep both import/migration sentinels so logging out cannot immediately
		// restore credentials from Micro.blog or legacy Sunlit settings.
		Settings.setValue("true", forKey: Settings.oneTimeImportKey)
		Settings.setValue(true, forKey: "3.0 to 3.1 settings migration")

		Snippets.Configuration.timeline = Snippets.Configuration.microblogConfiguration(token: "")
		Snippets.Configuration.publishing = Snippets.Configuration.timeline
	}

	static func beginSnippetsSignIn() {
		Settings.setValue(Date(), forKey: pendingSnippetsSignInDateKey)
	}

	static func cancelPendingSnippetsSignIn() {
		Settings.removeObject(forKey: pendingSnippetsSignInDateKey)
	}

	static func consumePendingSnippetsSignIn() -> Bool {
		guard let requestedAt = Settings.object(forKey: pendingSnippetsSignInDateKey) as? Date else {
			return false
		}

		Settings.removeObject(forKey: pendingSnippetsSignInDateKey)
		let age = Date().timeIntervalSince(requestedAt)
		return age >= 0.0 && age <= pendingSnippetsSignInLifetime
	}
	
	@discardableResult
	static func saveSnippetsToken(_ token : String) -> Bool {
		guard let data = token.data(using: .utf8) else {
			return false
		}

		guard let itemQuery = snippetsKeychainQuery() else {
			return false
		}
		var query = itemQuery
		query[kSecValueData] = data
		query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

		let status = SecItemAdd(query as CFDictionary, nil)
		if status == errSecDuplicateItem {
			let attributes: [CFString : Any] = [
				kSecValueData: data,
				kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
			]
			return SecItemUpdate(itemQuery as CFDictionary, attributes as CFDictionary) == errSecSuccess
		}

		return status == errSecSuccess
	}

	static func snippetsToken() -> String? {
		if let token = sharedSnippetsToken() {
			removeLegacySnippetsTokenStorage()
			Settings.setValue("true", forKey: Settings.oneTimeImportKey)
			return token
		}

        if let key = UUKeychain.getString(key: "SunlitToken") {
            Settings.setValue("true", forKey: Settings.oneTimeImportKey)

			if saveSnippetsToken(key) {
				removeLegacySnippetsTokenStorage()
			}
            return key
        }

        if let string = UUKeychain.getString(key: "Snippets") {
			if saveSnippetsToken(string) {
				removeLegacySnippetsTokenStorage()
			}
            Settings.setValue("true", forKey: Settings.oneTimeImportKey)
            return string
        }

        if let string = importMicroblogKeychain() {
            return string
        }

        if let string = Settings.object(forKey: "Snippets") as? String {
			if saveSnippetsToken(string) {
				removeLegacySnippetsTokenStorage()
			}
            return string
        }

		if let string = Settings.object(forKey: "SunlitToken") as? String {
			if saveSnippetsToken(string) {
				removeLegacySnippetsTokenStorage()
			}
			return string
		}

        return nil
	}

	static func deleteSnippetsToken() {
		if let query = snippetsKeychainQuery() {
			SecItemDelete(query as CFDictionary)
		}
		removeLegacySnippetsTokenStorage()
	}

	static private func sharedSnippetsToken() -> String? {
		guard var query = snippetsKeychainQuery() else {
			return nil
		}
		query[kSecReturnData] = true
		query[kSecMatchLimit] = kSecMatchLimitOne

		var result: CFTypeRef?
		guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
			  let data = result as? Data else {
			return nil
		}

		return String(data: data, encoding: .utf8)
	}

	static private func snippetsKeychainQuery() -> [CFString : Any]? {
		guard let accessGroup = Bundle.main.object(forInfoDictionaryKey: "SunlitKeychainAccessGroup") as? String,
			  !accessGroup.isEmpty,
			  !accessGroup.contains("$(") else {
			return nil
		}

		return [
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: snippetsKeychainService,
			kSecAttrAccount: snippetsKeychainAccount,
			kSecAttrAccessGroup: accessGroup
		]
	}

	static private func removeLegacySnippetsTokenStorage() {
		deleteInsecureString(forKey: "SunlitToken")
		deleteInsecureString(forKey: "Snippets")
		UUKeychain.remove(key: "SunlitToken")
		UUKeychain.remove(key: "Snippets")

		for service in legacySnippetsKeychainServices {
			for account in ["SunlitToken", "Snippets"] {
				let query: [CFString : Any] = [
					kSecClass: kSecClassGenericPassword,
					kSecAttrService: service,
					kSecAttrAccount: account.data(using: .utf8) as Any
				]
				SecItemDelete(query as CFDictionary)
			}
		}
	}

    
    static func importMicroblogKeychain() -> String? {

        if Settings.object(forKey: oneTimeImportKey) != nil {
            return nil
        }

        Settings.setValue("true", forKey: oneTimeImportKey)

        if let user = microblogUserName() {
            if let password = UUKeychain.password(forService: "Snippets", forAccount: user) {
                saveSnippetsToken(password)
                return password
            }
        }

        return nil
    }

    static func microblogUserName() -> String? {
        if let microBlogSettings = UserDefaults(suiteName: "group.blog.micro.ios") {
            if let username = microBlogSettings.object(forKey: "AccountUsername") as? String {
                return username
            }
        }

        return nil
    }

    static let oneTimeImportKey = "One Time Micro.blog Import"

}
