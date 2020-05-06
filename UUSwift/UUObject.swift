//
//  UUObject.swift
//  UUSwift
//
//  Created by Ryan DeVore on 7/18/19.
//  Copyright © 2019 Silverpine Software. All rights reserved.
//

import Foundation

public extension NSObject
{
    func uuAttach(object: Any?, for key: String)
    {
        objc_setAssociatedObject(self, key, object, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func uuObject(for key: String) -> Any?
    {
        return objc_getAssociatedObject(self, key)
    }
}
