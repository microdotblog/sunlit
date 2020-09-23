//
//  Snippets+Error.swift
//  Snippets
//
//  Created by Jonathan Hays on 9/6/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

#if os(macOS)
import AppKit
import UUSwift
#else
import UIKit
import UUSwift
#endif

extension Snippets {
    
    public enum SnippetsError : Error {
        case invalidOrMissingToken
    }

}
