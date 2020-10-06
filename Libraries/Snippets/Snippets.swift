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
    	

    @objc public func uploadVideo(data : Data, completion: @escaping(Error?, String?, String?)->()) -> UUHttpRequest? {
        if Snippets.Configuration.publishing.type == .micropub {
            return Snippets.Micropub.uploadVideo(Snippets.Configuration.publishing, data: data, completion: completion)
        }
        else { //XMLRPC currently doesn't support video upload
            return nil
        }
    }
    
    @objc public func uploadImage(image : SnippetsImage, completion: @escaping(Error?, String?)->()) -> UUHttpRequest? {
        if Snippets.Configuration.publishing.type == .micropub {
            return Snippets.Micropub.uploadImage(Snippets.Configuration.publishing, image: image, completion: completion)
        }
        else {
            let request = Snippets.XMLRPC.Request.publishPhotoRequest(identity: Snippets.Configuration.publishing)
            return Snippets.XMLRPC.uploadImage(image: image, request: request) { (error, imagePath, imageIdentifier) in
                completion(error, imagePath)
            }
        }
    }
    
    @objc public func updatePost(post : SnippetsPost, completion: @escaping(Error?) -> ()) -> UUHttpRequest? {
        if Snippets.Configuration.publishing.type == .micropub {
            return Snippets.Micropub.updatePost(Snippets.Configuration.publishing, post: post, completion: completion)
        }
        else {
            let request = Snippets.XMLRPC.Request.publishPostRequest(identity: Snippets.Configuration.publishing, existingPost: true)
            return Snippets.XMLRPC.editPost(postIdentifier: post.identifier, title: "", content: post.htmlText, postFormat: "", postCategory: "", request: request) { (error, pathToPost) in
                completion(error)
            }
        }
    }
    
    @objc public func delete(post : SnippetsPost, completion: @escaping(Error?) -> ()) -> UUHttpRequest? {
        if Snippets.Configuration.publishing.type == .micropub {
            return Snippets.Micropub.delete(Snippets.Configuration.publishing, post: post, completion: completion)
        }
        else {
            let request = Snippets.XMLRPC.Request.unpublishRequest(identity: Snippets.Configuration.publishing)
            return Snippets.XMLRPC.unpublish(postIdentifier: post.identifier, request: request, completion: completion)
        }
    }
    
    @objc public func postHtml(title : String, content : String, isDraft : Bool = false, completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest? {
        if Snippets.Configuration.publishing.type == .micropub {
            return Snippets.Micropub.postHtml(Snippets.Configuration.publishing, title: title, content: content, completion: completion)
        }
        else {
            let request = Snippets.XMLRPC.Request.publishPostRequest(identity: Snippets.Configuration.publishing, existingPost: false)
            
            
            return Snippets.XMLRPC.post(title: title, content: content, postFormat: "", postCategory: "", request: request) { (error, postIdentifier) in
                
                if let postIdentifier = postIdentifier {
                    let request = Snippets.XMLRPC.Request.fetchPostInfoRequest(identity: Snippets.Configuration.publishing)
                    _ = Snippets.XMLRPC.fetchPostURL(postIdentifier: postIdentifier, request: request, completion: completion)
                }
                else {
                    completion(error, nil)
                }
            }
        }
    }
    
    @objc public func postText(title : String, content : String, isDraft : Bool = false, photos : [String] = [], altTags : [String] = [], videos : [String] = [], videoAltTags : [String] = [], completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest? {
        if Snippets.Configuration.publishing.type == .micropub {
            return Snippets.Micropub.postText(Snippets.Configuration.publishing, title: title, content: content, isDraft: isDraft, photos: photos, altTags: altTags, videos: videos, videoAltTags: videoAltTags, completion: completion)
        }
        else { // WARNING! You really shouldn't call this because Wordpress/XMLRPC don't support this so we're just remapping it to an html post
            let request = Snippets.XMLRPC.Request.publishPostRequest(identity: Snippets.Configuration.publishing, existingPost: false)
            return Snippets.XMLRPC.post(title: title, content: content, postFormat: "", postCategory: "", request: request, completion: completion)
        }
    }

}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Path building functions
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extension Snippets {

    static public func secureGet(_ configuration: Snippets.Configuration, path : String, arguments : [String : String]) -> UUHttpRequest
    {
        let request = UUHttpRequest(url:path, method: .get, queryArguments: arguments, headers : ["Authorization" : "Bearer \(configuration.micropubToken)"])
        return request
    }

    static public func securePut(_ configuration: Snippets.Configuration, path : String, arguments : [String : String], body : Data? = nil) -> UUHttpRequest
    {
        let request = UUHttpRequest(url:path, method: .put,  queryArguments:arguments, headers : ["Authorization" : "Bearer \(configuration.micropubToken)"], body:body)
        return request
    }

    static public func securePost(_ configuration: Snippets.Configuration, path : String, arguments : [String : String], body : Data? = nil) -> UUHttpRequest
    {
        let request = UUHttpRequest(url:path, method: .post, queryArguments:arguments, headers : ["Authorization" : "Bearer \(configuration.micropubToken)"], body:body)
        return request
    }
    
    static public func secureDelete(_ configuration: Snippets.Configuration, path : String, arguments : [String : String]) -> UUHttpRequest
    {
        let request = UUHttpRequest(url: path, method: .delete, queryArguments: arguments)
        request.headerFields["Authorization"] = "Bearer \(configuration.micropubToken)"
        
        return request
    }

    static public func appendParameter(body : String, name : String, content : String) -> String
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
}
