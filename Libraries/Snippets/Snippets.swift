//
//  Snippets.swift
//  Snippets
//
//  Created by Jonathan Hays on 10/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#if os(macOS)
import AppKit
import UUSwift
#else
import UIKit
import UUSwift
#endif


public class Snippets : NSObject {
    
	@objc public static let shared = Snippets()
    
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Signin
	// Sign-in is generally a 2-step process. First, request an email with a temporary token. Then exchange the temporary token for a permanent token
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@objc public func requestUserLoginEmail(email: String, appName : String, redirect: String, completion: @escaping (Error?) -> ())
	{
		let arguments : [String : String] = [ 	"email" : email,
												"app_name" : appName,
												"redirect_url" : redirect ]
	
		UUHttpSession.post(url: self.pathForTimelineRoute("account/signin"), queryArguments: arguments, body: nil, contentType: nil) { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		}
	}
	
	@objc public func requestPermanentTokenFromTemporaryToken(token : String, completion: @escaping(Error?, String?) -> ())
	{
		let arguments : [String : String] = [ "token" : token ]
		
		UUHttpSession.post(url: self.pathForTimelineRoute("account/verify"), queryArguments: arguments, body: nil, contentType: nil) { (parsedServerResponse) in
			if let dictionary = parsedServerResponse.parsedResponse as? [ String : Any ]
			{
				if let permanentToken = dictionary["token"] as? String
				{
                    self.timelineConfiguration.token = permanentToken
				}
				
				completion(parsedServerResponse.httpError, self.timelineConfiguration.token)
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
	@objc public func fetchCurrentUserInfo(completion: @escaping(Error?, SnippetsUser?)-> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, nil)
			return
		}
		
        let arguments : [String : String] = [ "token" : self.timelineConfiguration.token ]
		let request = self.securePost(self.timelineConfiguration, path: self.pathForTimelineRoute("account/verify"), arguments: arguments)
		
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
	@objc public func fetchCurrentUserConfiguration(completion: @escaping(Error?, [String : Any])-> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.publishingConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, [:])
			return
		}

		let request = self.secureGet(self.publishingConfiguration, path: self.pathForPublishingRoute(), arguments: [ "q": "config" ])
		
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
	@objc public func fetchCurrentUserPosts(completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, [])
			return
		}
		
		var arguments = [ "q" : "source" ]
		if let blogUid = self.publishingConfiguration.uid {
			if blogUid.count > 0 {
				arguments["mp-destination"] = blogUid
			}
		}
		
		self.fetchTimeline(self.pathForPublishingRoute(), arguments:arguments, completion: completion)
	}
	
	@objc public func fetchCurrentUserTimeline(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
        // Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
            completion(SnippetsError.invalidOrMissingToken, [])
            return
        }

		self.fetchTimeline(self.pathForTimelineRoute("posts/all"), arguments:parameters, completion: completion)
	}
	
	@objc public func fetchCurrentUserPhotoTimeline(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
        // Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
            completion(SnippetsError.invalidOrMissingToken, [])
            return
        }

		self.fetchTimeline(self.pathForTimelineRoute("posts/photos"), arguments:parameters, completion: completion)
	}

	@objc public func fetchCurrentUserMediaTimeline(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
        // Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
            completion(SnippetsError.invalidOrMissingToken, [])
            return
        }

		self.fetchTimeline(self.pathForTimelineRoute("posts/media"), arguments: parameters, completion: completion)
	}

	@objc public func fetchCurrentUserMentions(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
        // Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
            completion(SnippetsError.invalidOrMissingToken, [])
            return
        }

		self.fetchTimeline(self.pathForTimelineRoute("posts/mentions"), arguments: parameters, completion: completion)
	}

	@objc public func fetchCurrentUserFavorites(parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
        // Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
            completion(SnippetsError.invalidOrMissingToken, [])
            return
        }

		self.fetchTimeline(self.pathForTimelineRoute("posts/favorites"), arguments: parameters, completion: completion)
	}
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Interface for querying other items outside the logged-in user
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@objc public func fetchDiscoverTimeline(collection : String? = nil, parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost], [[String : Any]]?) -> ())
	{
        var route = "posts/discover"
        if let validCollection = collection {
            route = "posts/discover/\(validCollection)"
        }
        
        let path = self.pathForTimelineRoute(route)
        let request = self.secureGet(self.timelineConfiguration, path: path, arguments: parameters)
        
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
    
    @objc public func fetchTagmojiCategories(completion: @escaping(Error?, [[String : Any]]) -> ())
    {
        self.fetchDiscoverTimeline { (error, posts, tagmoji) in
            var categories : [[String : Any]] = [ ]
            if let tagmojiList = tagmoji {
                categories = tagmojiList
            }
            
            completion(error, categories)
        }
    }

	@objc public func fetchUserPosts(user : SnippetsUser, parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
		let route = "posts/\(user.userName)"
		self.fetchTimeline(self.pathForTimelineRoute(route), arguments: parameters, completion: completion)
	}
	
	@objc public func fetchUserMediaPosts(user : SnippetsUser, parameters : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
		let route = "/posts/\(user.userName)/photos"
		self.fetchTimeline(self.pathForTimelineRoute(route), arguments: parameters, completion: completion)
	}
	
	@objc public func fetchConversation(post : SnippetsPost, completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
		let route = "posts/conversation?id=\(post.identifier)"
		self.fetchTimeline(self.pathForTimelineRoute(route), completion: completion)
	}

	@objc public func checkForPostsSince(post : SnippetsPost, completion: @escaping(Error?, NSInteger, TimeInterval) -> ())
	{
		let route = "posts/check?since_id=\(post.identifier)"
		let request = self.secureGet(self.timelineConfiguration, path: self.pathForTimelineRoute(route), arguments: [:])
		
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
	// MARK: - Follow Interface
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@objc public func fetchUserDetails(user : SnippetsUser, completion: @escaping(Error?, SnippetsUser?, [SnippetsPost]) -> ())
	{
		let route = "posts/\(user.userName)"

		let request = self.secureGet(self.timelineConfiguration, path: self.pathForTimelineRoute(route), arguments: [:])
	
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
	
	@objc public func follow(user : SnippetsUser, completion: @escaping(Error?) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken)
			return
		}

		let arguments : [ String : String ] = [ "username" : user.userName ]
		
		let request = self.securePost(self.timelineConfiguration, path: self.pathForTimelineRoute("users/follow"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}

	@objc public func unfollow(user : SnippetsUser, completion: @escaping(Error?) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken)
			return
		}

		let arguments : [ String : String ] = [ "username" : user.userName ]
		
		let request = self.securePost(self.timelineConfiguration, path: self.pathForTimelineRoute("users/unfollow"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	@objc public func checkFollowingStatus(user : SnippetsUser, completion: @escaping(Error?, Bool) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, false)
			return
		}
		
		let route = "users/is_following?username=\(user.userName)"
		let request = self.secureGet(self.timelineConfiguration, path: self.pathForTimelineRoute(route), arguments: [:])
		
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
	
	@objc public func listFollowing(user : SnippetsUser, completeList : Bool, completion: @escaping(Error?, [SnippetsUser]) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, [])
			return
		}
		
		var route = "users/following/\(user.userName)"
		if (!completeList)
		{
			route = "users/discover/\(user.userName)"
		}
		
		let request = self.secureGet(self.timelineConfiguration, path: self.pathForTimelineRoute(route), arguments: [:])
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

	@objc public func searchUsers(_ q: String, completion: @escaping(Error?, [SnippetsUser]) -> ())
	{
		// Pre-flight check to see if we are even configured...
		if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, [])
			return
		}
		
		let route = "users/search"
		let args: [ String: String ] = [ "q": q ]
		
		let request = self.secureGet(self.timelineConfiguration, path: self.pathForTimelineRoute(route), arguments: args)
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

	@objc public func favorite(post : SnippetsPost, completion: @escaping(Error?) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken)
			return
		}
		
		let arguments : [ String : String ] = [ "id" : post.identifier ]

		let request = self.securePost(self.timelineConfiguration, path: self.pathForTimelineRoute("favorites"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}

	@objc public func unfavorite(post : SnippetsPost, completion: @escaping(Error?) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken)
			return
		}
		
		let route = "favorites/\(post.identifier)"
		let request = self.secureDelete(self.timelineConfiguration, path: self.pathForTimelineRoute(route), arguments: [:])
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Post/Reply Interface
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	@objc public func postText(title : String, content : String, isDraft : Bool = false, photos : [String] = [], altTags : [String] = [], videos : [String] = [], videoAltTags : [String] = [], completion: @escaping(Error?, String?) -> ())
	{
		// Pre-flight check to see if we are even configured...
        if self.publishingConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, nil)
			return
		}
		
		var bodyText = ""
		bodyText = self.appendParameter(body: bodyText, name: "name", content: title)
		bodyText = self.appendParameter(body: bodyText, name: "content", content: content)
		bodyText = self.appendParameter(body: bodyText, name: "h", content: "entry")

		if let blogUid = self.publishingConfiguration.uid {
			if blogUid.count > 0 {
				bodyText = self.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
			}
		}

		for photoPath in photos {
			bodyText = self.appendParameter(body: bodyText, name: "photo[]", content: photoPath)
		}

		for altTag in altTags {
			bodyText = self.appendParameter(body: bodyText, name: "mp-photo-alt[]", content: altTag)
		}
		
		for videoPath in videos {
			bodyText = self.appendParameter(body: bodyText, name: "video[]", content: videoPath)
		}
		
		for altTag in videoAltTags {
			bodyText = self.appendParameter(body: bodyText, name: "mp-video-alt[]", content: altTag)
		}
		
		if isDraft {
			bodyText = self.appendParameter(body: bodyText, name: "post-status", content: "draft")
		}
		else {
			bodyText = self.appendParameter(body: bodyText, name: "post-status", content: "published")
		}

		let body : Data = bodyText.data(using: .utf8)!
		let request = self.securePost(self.publishingConfiguration, path: self.pathForPublishingRoute(), arguments: [:], body: body)
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
			completion(parsedServerResponse.httpError, publishedPath)
		})
	}
	
	@objc public func postHtml(title : String, content : String, isDraft : Bool = false, completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest?
	{
		// Pre-flight check to see if we are even configured...
        if self.publishingConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, nil)
			return nil
		}

		
		var properties : [ String : Any ] = [ "name" 	: [ title ],
											  "content" : [ [ "html" : content ] ]
											]

		if isDraft {
			properties["post-status"] = [ "draft" ]
		}
		else {
			properties["post-status"] = [ "published" ]
		}

		var arguments : [ String : Any ] = 	[	"type" : [ "h-entry" ],
												"properties" : properties
											]
		
		if let blogUid = self.publishingConfiguration.uid {
			if blogUid.count > 0 {
				arguments["mp-destination"] = blogUid
			}
		}
		
		do {
			let body = try JSONSerialization.data(withJSONObject: arguments, options: .prettyPrinted)
			
			let request = self.securePost(self.publishingConfiguration, path: self.pathForPublishingRoute(), arguments: [:], body: body)
			
			return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
				let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
				completion(parsedServerResponse.httpError, publishedPath)
			})
			
		}
		catch {
		}
		
		return nil
	}
	
	private func deletePostByUrl(path : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
	{
		var bodyText = ""
		bodyText = self.appendParameter(body: bodyText, name: "action", content: "delete")
		bodyText = self.appendParameter(body: bodyText, name: "url", content: path)
		if let blogUid = self.publishingConfiguration.uid {
			if blogUid.count > 0 {
				bodyText = self.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
			}
		}

		let body : Data = bodyText.data(using: .utf8)!
		let request = self.securePost(self.publishingConfiguration, path: self.pathForPublishingRoute(), arguments: [:], body: body)
		return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	private func deletePostByIdentifier(identifier : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
	{
		let route = "posts/\(identifier)"

		let request = self.secureDelete(self.timelineConfiguration, path: self.pathForTimelineRoute(route), arguments: [:])
		
		return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	@objc public func deletePost(post : SnippetsPost, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
	{
		// Pre-flight check to see if we are even configured...
        if self.publishingConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken)
			return nil
		}
		
		// There are actually two ways to delete posts. The safer way is if you have the post identifier
		// The other way is more of the "micropub" way in which you just have the path to the post
		if (post.identifier.count > 0)
		{
			return self.deletePostByIdentifier(identifier: post.identifier, completion: completion)
		}
		else
		{
			return self.deletePostByUrl(path: post.path, completion: completion)
		}
	}
	
	private func updatePostByUrl(path : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
	{
		var bodyText = ""
		bodyText = self.appendParameter(body: bodyText, name: "action", content: "update")
		bodyText = self.appendParameter(body: bodyText, name: "url", content: path)
		if let blogUid = self.publishingConfiguration.uid {
			if blogUid.count > 0 {
				bodyText = self.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
			}
		}

		let body : Data = bodyText.data(using: .utf8)!
        let request = self.securePost(self.publishingConfiguration, path: self.pathForPublishingRoute(), arguments: [:], body: body)
		return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	@objc public func updatePost(post : SnippetsPost, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
	{
		// Pre-flight check to see if we are even configured...
        if self.publishingConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken)
			return nil
		}
		
		return self.updatePostByUrl(path: post.path, completion: completion)
	}

	@objc public func reply(originalPost : SnippetsPost, content : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
	{
		// Pre-flight check to see if we are even configured...
        if self.timelineConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken)
			return nil
		}
		
		var arguments : [ String : String ] = [ "id" : originalPost.identifier,
											    "text" : content ]
		
        let request = self.securePost(self.timelineConfiguration, path: self.pathForTimelineRoute("posts/reply"), arguments: arguments)
		
		return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	
	@objc public func uploadImage(image : SnippetsImage, completion: @escaping(Error?, String?)->()) -> UUHttpRequest?
	{
		// Pre-flight check to see if we are even configured...
        if self.publishingConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, nil)
			return nil
		}
		
		var resizedImage = image
		if image.size.width > 1800.0
		{
			resizedImage = resizedImage.uuScaleToWidth(targetWidth: 1800.0 )
		}

		let imageData = resizedImage.uuJpegData(0.9)!
		var formData : Data = Data()
		let imageName = "file"
		let boundary = ProcessInfo.processInfo.globallyUniqueString

		if let blogUid = self.publishingConfiguration.uid {
			if blogUid.count > 0 {
				formData.append(String("--\(boundary)\r\n").data(using: String.Encoding.utf8)!)
				formData.append(String("Content-Disposition: form-data; name=\"mp-destination\"\r\n\r\n").data(using: String.Encoding.utf8)!)
				formData.append(String("\(blogUid)\r\n").data(using:String.Encoding.utf8)!)
			}
		}
		
		formData.append(String("--\(boundary)\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("Content-Disposition: form-data; name=\"\(imageName)\"; filename=\"image.jpg\"\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("Content-Type: image/jpeg\r\n\r\n").data(using: String.Encoding.utf8)!)
		formData.append(imageData)
		formData.append(String("\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("--\(boundary)--\r\n").data(using: String.Encoding.utf8)!)
		
        let request = self.securePost(self.publishingConfiguration, path: self.publishingConfiguration.mediaEndpoint, arguments: [:], body: formData)
		request.headerFields["Content-Type"] = "multipart/form-data; boundary=\(boundary)"

		return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			
			let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
			completion(parsedServerResponse.httpError, publishedPath)
		})
		
	}

	@objc public func uploadVideo(data : Data, completion: @escaping(Error?, String?, String?)->()) -> UUHttpRequest?
	{
		// Pre-flight check to see if we are even configured...
        if self.publishingConfiguration.token.count == 0 {
			completion(SnippetsError.invalidOrMissingToken, nil, nil)
			return nil
		}

		var formData : Data = Data()
		let imageName = "file"
		let boundary = ProcessInfo.processInfo.globallyUniqueString
				
		if let blogUid = self.publishingConfiguration.uid {
			if blogUid.count > 0 {
				formData.append(String("--\(boundary)\r\n").data(using: String.Encoding.utf8)!)
				formData.append(String("Content-Disposition: form-data; name=\"mp-destination\"\r\n\r\n").data(using: String.Encoding.utf8)!)
				formData.append(String("\(blogUid)\r\n").data(using:String.Encoding.utf8)!)
			}
		}
		
		formData.append(String("--\(boundary)\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("Content-Disposition: form-data; name=\"\(imageName)\"; filename=\"video.mov\"\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("Content-Type: video/mov\r\n\r\n").data(using: String.Encoding.utf8)!)
		formData.append(data)
		formData.append(String("\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("--\(boundary)--\r\n").data(using: String.Encoding.utf8)!)
		
		let request = self.securePost(self.publishingConfiguration, path: self.publishingConfiguration.mediaEndpoint, arguments: [:], body: formData)
		request.headerFields["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
		
		return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			
            var publishedPath : String? = nil
            var posterPath : String? = nil
            
            if let dictionary = parsedServerResponse.parsedResponse as? [String : Any] {
                publishedPath = dictionary["url"] as? String
                posterPath = dictionary["poster"] as? String
            }
			completion(parsedServerResponse.httpError, publishedPath, posterPath)
		})
		
	}
	
	private func pathForTimelineRoute(_ route : String) -> String
	{
        let fullPath : NSString = self.timelineConfiguration.endpoint as NSString
		return fullPath.appendingPathComponent(route) as String
	}

    private func pathForPublishingRoute(_ route : String = "") -> String
    {
		var fullPath: NSString = self.publishingConfiguration.micropubEndpoint as NSString
		if route.count > 0 {
			fullPath = fullPath.appendingPathComponent(route) as NSString
		}
		return fullPath as String
    }

    
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Private/internal helper functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private var internalTimelineConfiguration = Snippets.Configuration()
	private var internalPublishingConfiguration : Snippets.Configuration? = nil

    private func secureGet(_ configuration: Snippets.Configuration, path : String, arguments : [String : String]) -> UUHttpRequest
	{
        let request = UUHttpRequest(url:path, method: .get, queryArguments: arguments, headers : ["Authorization" : "Bearer \(configuration.token)"])
		return request
	}

	private func securePut(_ configuration: Snippets.Configuration, path : String, arguments : [String : String], body : Data? = nil) -> UUHttpRequest
	{
        let request = UUHttpRequest(url:path, method: .put,  queryArguments:arguments, headers : ["Authorization" : "Bearer \(configuration.token)"], body:body)
		return request
	}

	private func securePost(_ configuration: Snippets.Configuration, path : String, arguments : [String : String], body : Data? = nil) -> UUHttpRequest
	{
        let request = UUHttpRequest(url:path, method: .post, queryArguments:arguments, headers : ["Authorization" : "Bearer \(configuration.token)"], body:body)
		return request
	}
	
	private func secureDelete(_ configuration: Snippets.Configuration, path : String, arguments : [String : String]) -> UUHttpRequest
	{
		let request = UUHttpRequest(url: path, method: .delete, queryArguments: arguments)
        request.headerFields["Authorization"] = "Bearer \(configuration.token)"
		
		return request
	}

	private func appendParameter(body : String, name : String, content : String) -> String
	{
		var newBody = body
		if (body.count > 0 && content.count > 0)
		{
			newBody += "&"
		}

		if (content.count > 0 && name.count > 0)
		{
			newBody += "\(name.uuUrlEncoded())=\(content.uuUrlEncoded())"
		}
		
		return newBody
	}

	private func fetchTimeline(_ path : String, arguments : [String : String] = [:], completion: @escaping(Error?, [SnippetsPost]) -> ())
	{
        let request = self.secureGet(self.timelineConfiguration, path: path, arguments: arguments)
		
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

extension Snippets {
	
	public enum SnippetsError : Error {
		case invalidOrMissingToken
	}

}

extension Snippets {
    
    @objc public func configureTimeline(_ configuration : Snippets.Configuration) {
        self.timelineConfiguration = configuration
    }

    @objc public func configurePublishing(_ configuration : Snippets.Configuration) {
        self.publishingConfiguration = configuration
    }
    
    @objc public var publishingConfiguration : Configuration {
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

    @objc public var timelineConfiguration : Configuration {
        get {
            return self.internalTimelineConfiguration
        }
        set(configuration) {
            self.internalTimelineConfiguration = configuration
        }
    }
   
    public class Configuration : NSObject {
        
		public var token = ""
		public var endpoint = "https://micro.blog/"
		public var micropubEndpoint = "https://micro.blog/micropub"
		public var mediaEndpoint = "https://micro.blog/micropub/media"
		public var uid : String? = nil
        
        public static func reset() {
            Snippets.shared.timelineConfiguration.token = ""
            Snippets.shared.timelineConfiguration.endpoint = "https://micro.blog/"
            Snippets.shared.timelineConfiguration.micropubEndpoint = "https://micro.blog/micropub"
            Snippets.shared.timelineConfiguration.mediaEndpoint = "https://micro.blog/micropub/media"
            Snippets.shared.timelineConfiguration.uid = nil
            
            Snippets.shared.internalPublishingConfiguration = nil
        }
    }

}


