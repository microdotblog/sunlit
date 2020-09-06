//
//  Snippets+Configuration.swift
//  Snippets
//
//  Created by Jonathan Hays on 8/31/20.
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
       
    public class Configuration : NSObject {
        
        public enum host : Int {
            case micropub
            case xmlRPC
            case wordPress
        }
            
        public var type : host = .micropub
        
        public var microblogEndpoint = "https://micro.blog"
        
        public var micropubEndpoint = "https://micro.blog/micropub"
        public var micropubMediaEndpoint = "https://micro.blog/micropub/media"
        public var micropubToken = ""
        public var micropubUid : String? = nil
        
        public var xmlRpcEndpoint = ""
        public var xmlRpcUsername = ""
        public var xmlRpcPassword = ""
        public var xmlRpcBlogId = "0"
        
        public func microBlogPathForRoute(_ route : String = "") -> String
        {
            let fullPath : NSString = self.microblogEndpoint as NSString
            return fullPath.appendingPathComponent(route) as String
        }

        public func micropubPathForRoute(_ route : String = "") -> String
        {
            let fullPath : NSString = self.micropubEndpoint as NSString
            return fullPath.appendingPathComponent(route) as String
        }

        public static func microblogConfiguration(token : String, uid : String? = nil) -> Configuration {
            let config = Configuration()
            config.type = .micropub
            config.micropubToken = token
            config.micropubUid = uid
            config.microblogEndpoint = "https://micro.blog"
            config.micropubEndpoint = "https://micro.blog/micropub"
            config.micropubMediaEndpoint = "https://micro.blog/micropub/media"
            
            return config
        }
        
        public static func micropubConfiguration(token : String, endpoint : String, mediaEndPoint : String? = nil, uid : String? = nil) -> Configuration {
            let config = Configuration()
            config.type = .micropub
            config.micropubToken = token
            config.micropubEndpoint = endpoint
            config.micropubMediaEndpoint = mediaEndPoint ?? endpoint
            config.micropubUid = uid
            return config
        }
        
        public static func xmlRpcConfiguration(username : String, password : String, endpoint : String, mediaEndPoint : String? = nil, blogId : String? = nil) -> Configuration {
            let config = Configuration()
            config.type = .xmlRPC
            config.xmlRpcUsername = username
            config.xmlRpcPassword = password
            config.xmlRpcEndpoint = endpoint
            config.xmlRpcBlogId = blogId ?? "0"
            return config
        }

        public static func wordpressConfiguration(username : String, password : String, endpoint : String, mediaEndPoint : String? = nil, blogId : String? = nil) -> Configuration {
            let config = Configuration()
            config.type = .wordPress
            config.xmlRpcUsername = username
            config.xmlRpcPassword = password
            config.xmlRpcEndpoint = endpoint
            config.xmlRpcBlogId = blogId ?? "0"
            return config
        }

        private override init() {
        }
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - Private/internal helper functions
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        private static var internalTimelineConfiguration = Snippets.Configuration.microblogConfiguration(token: "")
        private static var internalPublishingConfiguration : Snippets.Configuration? = nil
    }

}

extension Snippets.Configuration {
    
    static func pathForTimelineRoute(_ route : String) -> String
    {
        let fullPath : NSString = Snippets.Configuration.timeline.microblogEndpoint as NSString
        return fullPath.appendingPathComponent(route) as String
    }

    static func pathForPublishingRoute(_ route : String = "") -> String
    {
        var fullPath: NSString = Snippets.Configuration.publishing.micropubEndpoint as NSString
        if route.count > 0 {
            fullPath = fullPath.appendingPathComponent(route) as NSString
        }
        return fullPath as String
    }

    
    @objc static public func configure(_ configuration : Snippets.Configuration, publishConfiguration : Snippets.Configuration? = nil) {
        
        self.internalTimelineConfiguration = configuration
        
        if let publishing = publishConfiguration {
            self.internalPublishingConfiguration = publishing
        }
    }
    
    @objc static public var publishing : Snippets.Configuration {
        get {
            if let config = self.internalPublishingConfiguration {
                return config
            }
            
            return self.internalTimelineConfiguration
        }
        set(configuration) {
            self.internalPublishingConfiguration = configuration
        }
    }

    @objc static public var timeline : Snippets.Configuration {
        get {
            return self.internalTimelineConfiguration
        }
        set(configuration) {
            self.internalTimelineConfiguration = configuration
        }
    }
    
}


extension Snippets.Configuration {
    
    public func toDictionary() -> [ String : Any ] {
        var dictionary : [String : Any] = [:]
        dictionary["type"] = self.type.rawValue
        dictionary["micropubEndpoint"] = self.micropubEndpoint
        dictionary["micropubMediaEndpoint"] = self.micropubMediaEndpoint
        dictionary["micropubToken"] = self.micropubToken
        if let micropubUid = self.micropubUid {
            dictionary["micropubUid"] = micropubUid
        }
        dictionary["xmlRpcEndpoint"] = self.xmlRpcEndpoint
        dictionary["xmlRpcUsername"] = self.xmlRpcUsername
        dictionary["xmlRpcPassword"] = self.xmlRpcPassword
        dictionary["xmlRpcBlogId"] = self.xmlRpcBlogId

        return dictionary
    }
    
    static public func fromDictionary(_ dictionary : [String : Any]) -> Snippets.Configuration {
        let type : Int = dictionary.uuSafeGetInt("type") ?? 0
        let host = Snippets.Configuration.host(rawValue: type) ?? .micropub
        let micropubEndpoint = dictionary.uuSafeGetString("micropubEndpoint") ?? ""
        let micropubMediaEndpoint = dictionary.uuSafeGetString("micropubMediaEndpoint") ?? ""
        let micropubToken = dictionary.uuSafeGetString("micropubToken") ?? ""
        let micropubUid = dictionary.uuSafeGetString("micropubUid")
        
        let xmlRpcEndpoint = dictionary.uuSafeGetString("xmlRpcEndpoint") ?? ""
        let xmlRpcUsername = dictionary.uuSafeGetString("xmlRpcUsername") ?? ""
        let xmlRpcPassword = dictionary.uuSafeGetString("xmlRpcPassword") ?? ""
        let xmlRpcBlogId = dictionary.uuSafeGetString("xmlRpcBlogId") ?? ""

        if host == .micropub {
            return Snippets.Configuration.micropubConfiguration(token: micropubToken, endpoint: micropubEndpoint, mediaEndPoint: micropubMediaEndpoint, uid: micropubUid)
        }
        else if host == .wordPress {
            return Snippets.Configuration.wordpressConfiguration(username: xmlRpcUsername, password: xmlRpcPassword, endpoint: xmlRpcEndpoint, blogId: xmlRpcBlogId)
        }
        else if host == .xmlRPC {
            return Snippets.Configuration.xmlRpcConfiguration(username: xmlRpcUsername, password: xmlRpcPassword, endpoint: xmlRpcEndpoint, blogId: xmlRpcBlogId)
        }
        
        return Snippets.Configuration.microblogConfiguration(token: micropubToken)
    }
}
