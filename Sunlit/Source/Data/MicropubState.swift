//
//  MicropubState.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/11/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

class MicropubState {

    static func save(state : String, name : String, purpose: BlogSettings.PublishingPurpose = .posts) {
        var dictionary : [String : String] = [:]

        if let saved = Settings.object(forKey: key) as? [String : String] {
            dictionary = saved
        }

        dictionary[state] = name
        Settings.setValue(dictionary, forKey: key)
        var purposes = Settings.object(forKey: purposeKey) as? [String: String] ?? [:]
        purposes[state] = purpose.rawValue
        Settings.setValue(purposes, forKey: purposeKey)
    }

    static func lookupBlogName(from state : String) -> String? {

        if let dictionary = Settings.object(forKey: key) as? [String : String] {
            return dictionary[state]
        }

        return nil
    }

    static func delete(blogName : String) {

        if var saved = Settings.object(forKey: key) as? [String : String] {
            saved.removeValue(forKey: blogName)
            Settings.setValue(saved, forKey: key)
        }

    }

    static func publishingPurpose(from state: String) -> BlogSettings.PublishingPurpose {
        let purposes = Settings.object(forKey: purposeKey) as? [String: String] ?? [:]
        return purposes[state].flatMap(BlogSettings.PublishingPurpose.init(rawValue:)) ?? .posts
    }

    private static var key = "Sunlit Micropub Lookup"
    private static let purposeKey = "Sunlit Micropub Publishing Purposes"
}

