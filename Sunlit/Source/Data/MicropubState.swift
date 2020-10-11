//
//  MicropubState.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/11/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import Foundation

class MicropubState {

    static func save(state : String, path : String) {
        var dictionary : [String : String] = [:]

        if let saved = Settings.object(forKey: key) as? [String : String] {
            dictionary = saved
        }

        dictionary[state] = path
        Settings.setValue(dictionary, forKey: key)
    }

    static func lookupEndpoint(from state : String) -> String? {

        if let dictionary = Settings.object(forKey: key) as? [String : String] {
            return dictionary[state]
        }

        return nil
    }

    static func delete(state : String) {

        if var saved = Settings.object(forKey: key) as? [String : String] {
            saved.removeValue(forKey: state)
            Settings.setValue(saved, forKey: key)
        }

    }

    private static var key = "Sunlit Micropub Lookup"
}

