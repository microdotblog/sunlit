//
//  MicropubState.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/11/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

class MicropubState {

    static func save(state : String, name : String) {
        var dictionary : [String : String] = [:]

        if let saved = Settings.object(forKey: key) as? [String : String] {
            dictionary = saved
        }

        dictionary[state] = name
        Settings.setValue(dictionary, forKey: key)
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

    private static var key = "Sunlit Micropub Lookup"
}

