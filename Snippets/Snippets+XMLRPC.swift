//
//  Snippets+XMLRPC.swift
//  SnippetsFramework
//
//  Created by Jonathan Hays on 12/17/18.
//  Copyright © 2018 Micro.blog. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

//import UUSwift


@objc public class SnippetsXMLRPCIdentity : NSObject {

	@objc static public func create(username : String, password : String, endpoint : String, blogId : String, wordPress : Bool) -> SnippetsXMLRPCIdentity {
		let identity = SnippetsXMLRPCIdentity()
		identity.blogUsername = username
		identity.blogPassword = password
		identity.endpoint = endpoint
		identity.wordPress = wordPress
		
		if blogId.count > 0 {
			identity.blogId = blogId
		}

		return identity
	}
	
	var blogId = "0"
	var blogUsername = ""
	var blogPassword = ""
	var endpoint = ""
	var wordPress = false
}


@objc public class SnippetsXMLRPCRequest : NSObject {

	@objc static public func publishPostRequest(identity : SnippetsXMLRPCIdentity, existingPost : Bool) -> SnippetsXMLRPCRequest {
	
		var method = ""
		if (identity.wordPress && existingPost) {
			method = "wp.editPost"
		}
		else if (identity.wordPress) {
			method = "wp.newPost"
		}
		else if (existingPost) {
			method = "metaWeblog.editPost"
		}
		else {
			method =  "metaWeblog.newPost"
		}

		return SnippetsXMLRPCRequest(identity : identity, method: method)
	}

	@objc static public func publishPhotoRequest(identity : SnippetsXMLRPCIdentity) -> SnippetsXMLRPCRequest {
		let method = "metaWeblog.newMediaObject"
		return SnippetsXMLRPCRequest(identity: identity, method: method)
	}

	@objc static public func unpublishRequest(identity : SnippetsXMLRPCIdentity) -> SnippetsXMLRPCRequest {
		let method = "metaWeblog.deletePost"
		return SnippetsXMLRPCRequest(identity : identity, method: method)
	}
	
	@objc static public func fetchPostInfoRequest(identity : SnippetsXMLRPCIdentity) -> SnippetsXMLRPCRequest {

		var method = "metaWeblog.getPost"
		if identity.wordPress {
			method = "wp.getPost"
		}

		return SnippetsXMLRPCRequest(identity : identity, method: method)
	}

	@objc public convenience init(identity : SnippetsXMLRPCIdentity, method : String) {
		self.init()

		self.identity = identity
		self.method = method
	}

	var identity : SnippetsXMLRPCIdentity = SnippetsXMLRPCIdentity()
	var method = ""
	
}


extension Snippets {

	@objc public func executeRPC(request : SnippetsXMLRPCRequest, params:[Any], completion: @escaping(Error?,Data?) -> ()) {
		
		let xmlRPCRequest = SnippetsRPCDiscovery(url: request.identity.endpoint)
		_ = xmlRPCRequest.sendMethod(method: request.method, params: params) { (response) in
			completion(response.httpError, response.rawResponse)
		}
	}

	@objc public func editPost(postIdentifier : String,
							   title : String,
							   content : String,
							   postFormat : String,
							   postCategory : String,
							   request : SnippetsXMLRPCRequest, completion: @escaping(Error?, String?) -> ()) {
		
		let params : [Any] = self.buildPostParameters(identity : request.identity,
													  postIdentifier: postIdentifier,
													  title: title,
													  htmlContent: content,
													  postFormat: postFormat,
													  postCategory: postCategory)

		self.executeRPC(request: request, params: params)
		{ (error, responseData) in

			if let data : Data = responseData {
				SnippetsXMLRPCParser.parsedResponseFromData(data, completion:
				{ (responseFault, responseParams) in
					if responseFault == nil {
						let postId : String? = responseParams.first as? String
						completion(error, postId)
						return
					}
					else {
						let error = self.buildCustomErrorFromResponseFault(responseFault!)
						completion(error, nil)
					}
				})
				
				return
			}
			
			completion(error, nil)
		}
	}


	@objc public func post(title : String,
						   content : String,
						   postFormat : String,
						   postCategory : String,
						   request : SnippetsXMLRPCRequest, completion: @escaping(Error?, String?) -> ()) {

		let params : [Any] = self.buildPostParameters(identity:request.identity,
													  postIdentifier: nil,
													  title: title,
													  htmlContent: content,
													  postFormat: postFormat,
													  postCategory: postCategory)
		
		self.executeRPC(request: request, params: params) { (error, responseData) in

			if let data : Data = responseData {
				SnippetsXMLRPCParser.parsedResponseFromData(data, completion: { (responseFault, responseParams) in
					if responseFault == nil {
						let postId : String? = responseParams.first as? String
						completion(error, postId)
						return
					}
					else {
						let error = self.buildCustomErrorFromResponseFault(responseFault!)
						completion(error, nil)
					}
				})
			}
			else {
				completion(error, nil)
			}
		}
	}
	

	@objc public func uploadImage(image : SnippetsImage, 	request : SnippetsXMLRPCRequest,
													completion: @escaping(Error?, String?, String?) -> ())
	{
		let d = image.uuJpegData(0.8)
		
		let filename = UUID().uuidString.replacingOccurrences(of: "-", with: "") + ".jpg"
		let params : [Any] = [ request.identity.blogId,
							   request.identity.blogUsername,
							   request.identity.blogPassword, [ "name" : filename,
													   "type" : "image/jpeg",
													   "bits": d! ]]

		self.executeRPC(request: request, params: params) { (error, responseData) in
			if let data : Data = responseData {
				SnippetsXMLRPCParser.parsedResponseFromData(data, completion: { (responseFault, responseParams) in

					if responseFault == nil {
						var imageUrl : String? = nil
						var imageIdentifier : String? = nil
					
						if let imageDictionary = responseParams.first as? NSDictionary {
							imageUrl = imageDictionary.object(forKey: "url") as? String
							if (imageUrl == nil) {
								imageUrl = imageDictionary.object(forKey: "link") as? String
							}
						
							imageIdentifier = imageDictionary.object(forKey: "id") as? String
						
							if imageUrl != nil && imageIdentifier == nil {
								imageIdentifier = ""
							}
						}
						
					
						completion(error, imageUrl, imageIdentifier)
						return
					}
					else {
						let error = self.buildCustomErrorFromResponseFault(responseFault!)
						completion(error, nil, nil)
					}
				})
			}
			else {
				completion(error, nil, nil)
			}
		}
	}

	@objc public func uploadVideo(data : Data, 	request : SnippetsXMLRPCRequest,
								  completion: @escaping(Error?, String?, String?) -> ())
	{
		
		let filename = UUID().uuidString.replacingOccurrences(of: "-", with: "") + ".mov"
		let params : [Any] = [ request.identity.blogId,
							   request.identity.blogUsername,
							   request.identity.blogPassword, [ "name" : filename,
																"type" : "video/mov",
																"bits": data ]]
		
		self.executeRPC(request: request, params: params) { (error, responseData) in
			if let data : Data = responseData {
				SnippetsXMLRPCParser.parsedResponseFromData(data, completion: { (responseFault, responseParams) in
					
					if responseFault == nil {
						var imageUrl : String? = nil
						var imageIdentifier : String? = nil
						
						if let imageDictionary = responseParams.first as? NSDictionary {
							imageUrl = imageDictionary.object(forKey: "url") as? String
							if (imageUrl == nil) {
								imageUrl = imageDictionary.object(forKey: "link") as? String
							}
							
							imageIdentifier = imageDictionary.object(forKey: "id") as? String
							
							if imageUrl != nil && imageIdentifier == nil {
								imageIdentifier = ""
							}
						}
						
						
						completion(error, imageUrl, imageIdentifier)
						return
					}
					else {
						let error = self.buildCustomErrorFromResponseFault(responseFault!)
						completion(error, nil, nil)
					}
				})
			}
			else {
				completion(error, nil, nil)
			}
		}
	}
	
	@objc public func unpublish(postIdentifier : String, request : SnippetsXMLRPCRequest, completion: @escaping(Error?) -> ()) {

		let params : [Any] = [ "", postIdentifier, request.identity.blogUsername, request.identity.blogPassword ]
		
		self.executeRPC(request: request, params: params) { (error, responseData) in
			if let data : Data = responseData {
				SnippetsXMLRPCParser.parsedResponseFromData(data, completion: { (responseFault, responseParams) in
					if let fault = responseFault {
				
						let error = self.buildCustomErrorFromResponseFault(fault)

						//Check for a 404 in which case, this post is unpublished so there's no error...
						if error.code == 404 {
							completion(nil)
							return
						}
						
						completion(error)
					}
				})
			}
			else {
				completion(error)
			}
		}
	}

	@objc public func fetchPostURL(postIdentifier : String, request : SnippetsXMLRPCRequest, completion: @escaping(Error?, String?) -> ()) {
		
		var params : [Any] = [ postIdentifier, request.identity.blogUsername, request.identity.blogPassword ]
		if request.identity.wordPress == true {
			params.append(postIdentifier)
			params.append(["link"])
		}

		self.executeRPC(request: request, params: params) { (error, responseData) in
			if let data : Data = responseData {
				SnippetsXMLRPCParser.parsedResponseFromData(data, completion: { (responseFault, responseParams) in
					if let responseDictionary = responseParams.first as? NSDictionary {
						var url : String? = responseDictionary.object(forKey: "url") as? String
						if (url == nil) {
							url = responseDictionary.object(forKey: "link") as? String
						}
					
						completion(error, url)
						return
					}
					else {
						completion(error, nil)
					}
				})
			}
			else {
				completion(error, nil)
			}
		}
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Private
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private func buildCustomErrorFromResponseFault(_ responseFault : [String : Any]) -> NSError
	{
		var error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey:"Unknown error received from XMLRPC request"])
		
		if let faultString = responseFault["faultString"] as? String
		{
			var faultCode = responseFault["faultCode"] as? String ?? ""
			
			if let faultValue = responseFault["faultCode"] as? Int {
				faultCode = "error: \(faultValue)"
			}
			let composedString = faultString + "(\(faultCode))"
			let errorCode = 311 // cfErrorHTTPParseFailure
			error = NSError(domain: faultString, code: errorCode, userInfo: [NSLocalizedDescriptionKey:composedString,
																			 NSLocalizedFailureReasonErrorKey : composedString])
		}
		
		return error
	}
	
	private func buildPostParameters(identity : SnippetsXMLRPCIdentity,
									 postIdentifier : String?,
									 title : String,
									 htmlContent : String,
									 postFormat : String,
									 postCategory : String) -> [Any] {
	
		let content = NSMutableDictionary()
		
		if identity.wordPress {
			content["post_status"] = "publish"
			content["post_content"] = htmlContent
			if postFormat.count > 0 {
				content["post_format"] = postFormat
			}
			if postCategory.count > 0 {
				content["terms"] = ["category" : [postCategory] ]
			}
			if title.count > 0 {
				content["post_title"] = title
			}
		}
		else {
			content["description"] = htmlContent
			if title.count > 0 {
				content["title"] = title
			}
		}

		var params : [Any] = [ ]
		let publish = MBBoolean(true)

		if let publishedGUID = postIdentifier {
			if identity.wordPress == true {
				params = [ identity.blogId, identity.blogUsername, identity.blogPassword, publishedGUID, content ]
			}
			else {
				params = [ publishedGUID, identity.blogUsername, identity.blogPassword, content, publish ]
			}
		}
		else {
			if identity.wordPress == true {
				params = [ identity.blogId, identity.blogUsername, identity.blogPassword, content ]
			}
			else {
				params = [ identity.blogId, identity.blogUsername, identity.blogPassword, content, publish ]
			}
		}
		return params
	}
}
