//
//  MicropubState.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/11/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

class MicropubState {

    static func save(state : String, name : String, purpose: BlogSettings.PublishingPurpose = .posts, verifier: String? = nil, me: String? = nil) {
        var dictionary : [String : String] = [:]

        if let saved = Settings.object(forKey: key) as? [String : String] {
            dictionary = saved
        }

        dictionary[state] = name
        Settings.setValue(dictionary, forKey: key)
        var purposes = Settings.object(forKey: purposeKey) as? [String: String] ?? [:]
        purposes[state] = purpose.rawValue
        Settings.setValue(purposes, forKey: purposeKey)
        if let verifier = verifier {
            Settings.setSecureString(verifier, forKey: verifierKey + state)
        }
        if let me = me {
            var identities = Settings.object(forKey: identityKey) as? [String: String] ?? [:]
            identities[state] = me
            Settings.setValue(identities, forKey: identityKey)
        }
    }

    static func lookupBlogName(from state : String) -> String? {

        if let dictionary = Settings.object(forKey: key) as? [String : String] {
            return dictionary[state]
        }

        return nil
    }

    static func delete(blogName : String) {
        let saved = Settings.object(forKey: key) as? [String: String] ?? [:]
        for (state, name) in saved where name == blogName {
            remove(state: state)
        }
    }

    static func codeVerifier(from state: String) -> String? {
        return Settings.getSecureString(forKey: verifierKey + state)
    }

    static func identity(from state: String) -> String? {
        return (Settings.object(forKey: identityKey) as? [String: String])?[state]
    }

    static func remove(state: String) {
        for storageKey in [key, purposeKey, identityKey] {
            var saved = Settings.object(forKey: storageKey) as? [String: String] ?? [:]
            saved.removeValue(forKey: state)
            Settings.setValue(saved, forKey: storageKey)
        }
        Settings.deleteSecureString(forKey: verifierKey + state)
    }

    static func clear() {
        let saved = Settings.object(forKey: key) as? [String: String] ?? [:]
        for state in saved.keys { remove(state: state) }
    }

    static func publishingPurpose(from state: String) -> BlogSettings.PublishingPurpose {
        let purposes = Settings.object(forKey: purposeKey) as? [String: String] ?? [:]
        return purposes[state].flatMap(BlogSettings.PublishingPurpose.init(rawValue:)) ?? .posts
    }

    private static var key = "Sunlit Micropub Lookup"
    private static let purposeKey = "Sunlit Micropub Publishing Purposes"
    private static let identityKey = "Sunlit Micropub Identities"
    private static let verifierKey = "Sunlit Micropub Code Verifier "
}

