//
//  SnippetsLocation.swift
//  Snippets
//
//  Created by Manton Reece on 8/7/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

import Foundation
import CoreLocation

open class SnippetsLocation : NSObject
{
	@objc public var longitude: CLLocationDegrees = 0.0
	@objc public var latitude: CLLocationDegrees = 0.0
	@objc public var name = ""
	@objc public var url = ""
}
