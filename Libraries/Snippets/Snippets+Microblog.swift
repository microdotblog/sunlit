//
//  Snippets+Microblog.swift
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
    public class Microblog {
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - Signin
        // Sign-in is generally a 2-step process. First, request an email with a temporary token. Then exchange the temporary token for a permanent token
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        @objc static public func requestUserLoginEmail(email: String, appName : String, redirect: String, completion: @escaping (Error?) -> ())
        {
            let arguments : [String : String] = [     "email" : email,
                                                    "app_name" : appName,
                                                    "redirect_url" : redirect ]
        
            UUHttpSession.post(url: Snippets.Configuration.pathForTimelineRoute("account/signin"), queryArguments: arguments, body: nil, contentType: nil) { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            }
        }
        
        @objc static public func requestPermanentTokenFromTemporaryToken(token : String, completion: @escaping(Error?, String?) -> ())
        {
            let arguments : [String : String] = [ "token" : token ]
            
            UUHttpSession.post(url: "https://micro.blog/account/verify", queryArguments: arguments, body: nil, contentType: nil) { (parsedServerResponse) in
                if let dictionary = parsedServerResponse.parsedResponse as? [ String : Any ]
                {
                    var error = parsedServerResponse.httpError
                    if let permanentToken = dictionary["token"] as? String
                    {
                        Snippets.Configuration.timeline.micropubToken = permanentToken
                    }
                    else if let _ = dictionary["error"] as? String {
                        error = SnippetsError.invalidOrMissingToken
                    }
                    
                    completion(error, Snippets.Configuration.timeline.micropubToken)
                }
                else
                {
                    completion(parsedServerResponse.httpError, nil)
                }
            }
        }
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - User Info
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        // Returns a SnippetsUser for the currently signed-in user
        @objc static public func fetchCurrentUserInfo(completion: @escaping(Error?, SnippetsUser?)-> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, nil)
                return
            }
            
            let arguments : [String : String] = [ "token" : Snippets.Configuration.timeline.micropubToken ]
            let request = Snippets.securePost(Snippets.Configuration.timeline, path: Snippets.Configuration.timeline.microBlogPathForRoute("account/verify"), arguments: arguments)
            
            _ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
                if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
                {
                    let user = SnippetsUser(dictionary)
                    completion(parsedServerResponse.httpError, user)
                }
                else
                {
                    completion(parsedServerResponse.httpError, nil)
                }
            }
        }

        // User configuration pertains to the configuration of the Micro.blog account. For example, if a user has multiple micro.blogs,
        // fetching the configuration will return the list of configured micro.blogs for the signed-in user.
        @objc static public func fetchCurrentUserConfiguration(completion: @escaping(Error?, [String : Any])-> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [:])
                return
            }

            let request = Snippets.secureGet(Snippets.Configuration.publishing, path: Snippets.Configuration.publishing.micropubPathForRoute(), arguments: [ "q": "config" ])
            
            _ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
                
                if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
                {
                    completion(parsedServerResponse.httpError, dictionary)
                }
                else
                {
                    completion(parsedServerResponse.httpError, [:])
                }
            }

        }
        

        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - Timeline interface for the signed-in user
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        // Fetch all posts by the current logged in user, including draft posts.
        @objc static public func fetchCurrentUserPosts(completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.publishing.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }
            
            var arguments = [ "q" : "source" ]
            if let blogUid = Snippets.Configuration.publishing.micropubUid {
                if blogUid.count > 0 {
                    arguments["mp-destination"] = blogUid
                }
            }
            
            self.fetchTimeline(Snippets.Configuration.pathForPublishingRoute(), arguments:arguments, completion: completion)
        }
        
        @objc static public func fetchCurrentUserTimeline(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }

            self.fetchTimeline(Snippets.Configuration.pathForTimelineRoute("posts/all"), arguments:parameters, completion: completion)
        }
        
        @objc static public func fetchCurrentUserPhotoTimeline(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }

            self.fetchTimeline(Snippets.Configuration.pathForTimelineRoute("posts/photos"), arguments:parameters, completion: completion)
        }

        @objc static public func fetchCurrentUserMediaTimeline(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }

            self.fetchTimeline(Snippets.Configuration.pathForTimelineRoute("posts/media"), arguments: parameters, completion: completion)
        }

        @objc static public func fetchCurrentUserMentions(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }

            self.fetchTimeline(Snippets.Configuration.pathForTimelineRoute("posts/mentions"), arguments: parameters, completion: completion)
        }

        @objc static public func fetchCurrentUserFavorites(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }

            self.fetchTimeline(Snippets.Configuration.pathForTimelineRoute("posts/favorites"), arguments: parameters, completion: completion)
        }
        
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - Interface for querying other items outside the logged-in user
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        @objc static public func fetchDiscoverTimeline(collection : String? = nil, parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost], [[String : Any]]?) -> ())
        {
            var route = "posts/discover"
            if let validCollection = collection {
                route = "posts/discover/\(validCollection)"
            }
            
            let path = Snippets.Configuration.timeline.microBlogPathForRoute(route)
            let request = Snippets.secureGet(Snippets.Configuration.timeline, path: path, arguments: parameters)
            
            _ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
                if let feedDictionary = parsedServerResponse.parsedResponse as? [String : Any]
                {
                    if let items = feedDictionary["items"] as? [[String : Any]]
                    {
                        var posts : [ SnippetsPost ] = []
                        var tagmoji : [[String : Any]]? = nil
                        
                        for dictionary : [String : Any] in items
                        {
                            let post = SnippetsPost(dictionary)
                            posts.append(post)
                        }

                        if let microblogExtension = feedDictionary["_microblog"] as? [String : Any] {
                            tagmoji = microblogExtension["tagmoji"] as? [[String : Any]]
                        }

                        completion(parsedServerResponse.httpError, posts, tagmoji)
                    }
                }
                else
                {
                    completion(parsedServerResponse.httpError, [], nil)
                }
            }
        }
        
        @objc static public func fetchTagmojiCategories(completion: @escaping(Error?, [[String : Any]]) -> ())
        {
            self.fetchDiscoverTimeline { (error, posts, tagmoji) in
                var categories : [[String : Any]] = [ ]
                if let tagmojiList = tagmoji {
                    categories = tagmojiList
                }
                
                completion(error, categories)
            }
        }

        @objc static public func fetchUserPosts(user : SnippetsUser, parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            let route = "posts/\(user.userName)"
            self.fetchTimeline(Snippets.Configuration.timeline.microBlogPathForRoute(route), arguments: parameters, completion: completion)
        }
        
        @objc static public func fetchUserMediaPosts(user : SnippetsUser, parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            let route = "/posts/\(user.userName)/photos"
            self.fetchTimeline(Snippets.Configuration.pathForTimelineRoute(route), arguments: parameters, completion: completion)
        }
        
        @objc static public func fetchConversation(post : SnippetsPost, completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            let route = "posts/conversation?id=\(post.identifier)"
            self.fetchTimeline(Snippets.Configuration.pathForTimelineRoute(route), completion: completion)
        }

        @objc static public func checkForPostsSince(post : SnippetsPost, completion: @escaping(Error?, NSInteger, TimeInterval) -> ())
        {
            let route = "posts/check?since_id=\(post.identifier)"
            let request = Snippets.secureGet(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute(route), arguments: [:])
            
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                
                if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
                {
                    if let count = dictionary["count"] as? NSNumber,
                        let timeInterval = dictionary["check_seconds"] as? NSNumber
                    {
                        completion(parsedServerResponse.httpError, count.intValue, TimeInterval(timeInterval.floatValue))
                        return
                    }
                }

                completion(parsedServerResponse.httpError, 0, 0)
            })
        }

        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - Post/Reply Interface
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        @objc static public func reply(originalPost : SnippetsPost, content : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken)
                return nil
            }
            
            let arguments : [ String : String ] = [ "id" : originalPost.identifier,
                                                    "text" : content ]
            
            let request = Snippets.securePost(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute("posts/reply"), arguments: arguments)
            
            return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - Follow Interface
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        @objc static public func fetchUserDetails(user : SnippetsUser, completion: @escaping(Error?, SnippetsUser?, [SnippetsPost]) -> ())
        {
            let route = "posts/\(user.userName)"

            let request = Snippets.secureGet(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute(route), arguments: [:])
        
            _ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
                if let feedDictionary = parsedServerResponse.parsedResponse as? [String : Any]
                {
                    var updatedUser = user
                    var posts : [ SnippetsPost ] = []
                    if let author = feedDictionary["author"] as? [String : Any]
                    {
                        updatedUser = SnippetsUser(author)
                    }
                    if let microblogExtension = feedDictionary["_microblog"] as? [String : Any]
                    {
                        updatedUser.loadFromMicroblogDictionary(microblogExtension)
                    }
                    if let items = feedDictionary["items"] as? [[String : Any]]
                    {
                        for dictionary : [String : Any] in items
                        {
                            let post = SnippetsPost(dictionary)
                            posts.append(post)
                        }
                    }
                    
                    completion(parsedServerResponse.httpError, updatedUser, posts)
                }
                else
                {
                    completion(parsedServerResponse.httpError, user, [])
                }
            }
        }
        
        @objc static public func follow(user : SnippetsUser, completion: @escaping(Error?) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken)
                return
            }

            let arguments : [ String : String ] = [ "username" : user.userName ]
            
            let request = Snippets.securePost(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute("users/follow"), arguments: arguments)
            
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }

        @objc static public func unfollow(user : SnippetsUser, completion: @escaping(Error?) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken)
                return
            }

            let arguments : [ String : String ] = [ "username" : user.userName ]
            
            let request = Snippets.securePost(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute("users/unfollow"), arguments: arguments)
            
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }
        
        @objc static public func checkFollowingStatus(user : SnippetsUser, completion: @escaping(Error?, Bool) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, false)
                return
            }
            
            let route = "users/is_following?username=\(user.userName)"
            let request = Snippets.secureGet(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute(route), arguments: [:])
            
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                
                if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
                {
                    if let following = dictionary["is_following"] as? NSNumber
                    {
                        completion(parsedServerResponse.httpError, following.boolValue)
                        return
                    }
                }

                completion(parsedServerResponse.httpError, false)
            })
        }
        
        @objc static public func listFollowing(user : SnippetsUser, completeList : Bool, completion: @escaping(Error?, [SnippetsUser]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }
            
            var route = "users/following/\(user.userName)"
            if (!completeList)
            {
                route = "users/discover/\(user.userName)"
            }
            
            let request = Snippets.secureGet(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute(route), arguments: [:])
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                
                if let userDictionaryList = parsedServerResponse.parsedResponse as? [[String : Any]]
                {
                    var userList : [SnippetsUser] = []
                        
                    for userDictionary : [String : Any] in userDictionaryList
                    {
                        let user = SnippetsUser(userDictionary)
                        userList.append(user)
                    }
                        
                    completion(parsedServerResponse.httpError, userList)
                }
                else
                {
                    completion(parsedServerResponse.httpError, [])
                }
            })
        }

        @objc static public func searchUsers(_ q: String, done: Bool = false, completion: @escaping(Error?, [SnippetsUser]) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, [])
                return
            }
            
            let route = "users/search"
            var args: [ String: String ] = [ "q": q ]
            
            if done {
                args["done"] = "1"
            }
            
            let request = Snippets.secureGet(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute(route), arguments: args)
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                
                if let userDictionaryList = parsedServerResponse.parsedResponse as? [[String : Any]]
                {
                    var userList : [SnippetsUser] = []
                        
                    for userDictionary : [String : Any] in userDictionaryList
                    {
                        let user = SnippetsUser(userDictionary)
                        userList.append(user)
                    }
                        
                    completion(parsedServerResponse.httpError, userList)
                }
                else
                {
                    completion(parsedServerResponse.httpError, [])
                }
            })
        }

        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // MARK: - Favorite Interface
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        @objc static public func favorite(post : SnippetsPost, completion: @escaping(Error?) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken)
                return
            }
            
            let arguments : [ String : String ] = [ "id" : post.identifier ]

            let request = Snippets.securePost(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute("favorites"), arguments: arguments)
            
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }

        @objc static public func unfavorite(post : SnippetsPost, completion: @escaping(Error?) -> ())
        {
            // Pre-flight check to see if we are even configured...
            if Snippets.Configuration.timeline.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken)
                return
            }
            
            let route = "favorites/\(post.identifier)"
            let request = Snippets.secureDelete(Snippets.Configuration.timeline, path: Snippets.Configuration.pathForTimelineRoute(route), arguments: [:])
            
            _ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }
        
        static func fetchTimeline(_ path : String, arguments : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
        {
            let request = Snippets.secureGet(Snippets.Configuration.timeline, path: path, arguments: arguments)
            
            _ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
                if let feedDictionary = parsedServerResponse.parsedResponse as? [String : Any]
                {
                    if let items = feedDictionary["items"] as? [[String : Any]]
                    {
                        var posts : [ SnippetsPost ] = []
                        
                        for dictionary : [String : Any] in items
                        {
                            let post = SnippetsPost(dictionary)
                            posts.append(post)
                        }
                        
                        completion(parsedServerResponse.httpError, posts)
                    }
                }
                else
                {
                    completion(parsedServerResponse.httpError, [])
                }
            }
        }
    }
}
