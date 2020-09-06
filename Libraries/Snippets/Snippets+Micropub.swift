//
//  Snippets+Micropub.swift
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
  
    class Micropub {

        static func postText(_ identity : Snippets.Configuration, title : String, content : String, isDraft : Bool = false, photos : [String] = [], altTags : [String] = [], videos : [String] = [], videoAltTags : [String] = [], completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest?
        {
            // Pre-flight check to see if we are even configured...
            if identity.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, nil)
                return nil
            }
            
            var bodyText = ""
            bodyText = Snippets.appendParameter(body: bodyText, name: "name", content: title)
            bodyText = Snippets.appendParameter(body: bodyText, name: "content", content: content)
            bodyText = Snippets.appendParameter(body: bodyText, name: "h", content: "entry")

            if let blogUid = identity.micropubUid {
                if blogUid.count > 0 {
                    bodyText = Snippets.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
                }
            }

            for photoPath in photos {
                bodyText = Snippets.appendParameter(body: bodyText, name: "photo[]", content: photoPath)
            }

            for altTag in altTags {
                bodyText = Snippets.appendParameter(body: bodyText, name: "mp-photo-alt[]", content: altTag)
            }
            
            for videoPath in videos {
                bodyText = Snippets.appendParameter(body: bodyText, name: "video[]", content: videoPath)
            }
            
            for altTag in videoAltTags {
                bodyText = Snippets.appendParameter(body: bodyText, name: "mp-video-alt[]", content: altTag)
            }
            
            if isDraft {
                bodyText = Snippets.appendParameter(body: bodyText, name: "post-status", content: "draft")
            }
            else {
                bodyText = Snippets.appendParameter(body: bodyText, name: "post-status", content: "published")
            }

            let body : Data = bodyText.data(using: .utf8)!
            let request = Snippets.securePost(identity, path: identity.micropubPathForRoute(), arguments: [:], body: body)
            
            return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
                completion(parsedServerResponse.httpError, publishedPath)
            })
        }
        
        static func postHtml(_ identity : Snippets.Configuration, title : String, content : String, isDraft : Bool = false, completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest?
        {
            // Pre-flight check to see if we are even configured...
            if identity.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, nil)
                return nil
            }

            
            var properties : [ String : Any ] = [ "name"     : [ title ],
                                                  "content" : [ [ "html" : content ] ]
                                                ]

            if isDraft {
                properties["post-status"] = [ "draft" ]
            }
            else {
                properties["post-status"] = [ "published" ]
            }

            var arguments : [ String : Any ] =     [    "type" : [ "h-entry" ],
                                                    "properties" : properties
                                                ]
            
            if let blogUid = identity.micropubUid {
                if blogUid.count > 0 {
                    arguments["mp-destination"] = blogUid
                }
            }
            
            do {
                let body = try JSONSerialization.data(withJSONObject: arguments, options: .prettyPrinted)
                
                let request = Snippets.securePost(identity, path: identity.micropubPathForRoute(), arguments: [:], body: body)
                request.bodyContentType = UUContentType.applicationJson
                
                return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                    let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
                    completion(parsedServerResponse.httpError, publishedPath)
                })
                
            }
            catch {
            }
            
            return nil
        }
        
        static func deletePostByUrl(_ identity : Snippets.Configuration, path : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
        {
            var bodyText = ""
            bodyText = Snippets.appendParameter(body: bodyText, name: "action", content: "delete")
            bodyText = Snippets.appendParameter(body: bodyText, name: "url", content: path)
            if let blogUid = identity.micropubUid {
                if blogUid.count > 0 {
                    bodyText = Snippets.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
                }
            }

            let body : Data = bodyText.data(using: .utf8)!
            let request = Snippets.securePost(identity, path: identity.micropubPathForRoute(), arguments: [:], body: body)
            return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }
        
        static func deletePostByIdentifier(_ identity : Snippets.Configuration, identifier : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
        {
            let route = "posts/\(identifier)"

            let request = Snippets.secureDelete(identity, path: identity.micropubPathForRoute(route), arguments: [:])
            
            return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }
        
        static func deletePost(_ identity : Snippets.Configuration, post : SnippetsPost, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
        {
            // Pre-flight check to see if we are even configured...
            if identity.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken)
                return nil
            }
            
            // There are actually two ways to delete posts. The safer way is if you have the post identifier
            // The other way is more of the "micropub" way in which you just have the path to the post
            if (post.identifier.count > 0)
            {
                return self.deletePostByIdentifier(identity, identifier: post.identifier, completion: completion)
            }
            else
            {
                return self.deletePostByUrl(identity, path: post.path, completion: completion)
            }
        }
        
        static func updatePostByUrl(_ identity : Snippets.Configuration, path : String, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
        {
            var bodyText = ""
            bodyText = Snippets.appendParameter(body: bodyText, name: "action", content: "update")
            bodyText = Snippets.appendParameter(body: bodyText, name: "url", content: path)
            if let blogUid = identity.micropubUid {
                if blogUid.count > 0 {
                    bodyText = Snippets.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
                }
            }

            let body : Data = bodyText.data(using: .utf8)!
            let request = Snippets.securePost(identity, path: identity.micropubPathForRoute(), arguments: [:], body: body)
            return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                completion(parsedServerResponse.httpError)
            })
        }
        
        static func updatePost(_ identity : Snippets.Configuration, post : SnippetsPost, completion: @escaping(Error?) -> ()) -> UUHttpRequest?
        {
            // Pre-flight check to see if we are even configured...
            if identity.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken)
                return nil
            }
            
            return self.updatePostByUrl(identity, path: post.path, completion: completion)
        }
        
        
        static func uploadImage(_ identity : Snippets.Configuration, image : SnippetsImage, completion: @escaping(Error?, String?)->()) -> UUHttpRequest?
        {
            // Pre-flight check to see if we are even configured...
            if identity.micropubToken.count == 0 {
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

            if let blogUid = identity.micropubUid {
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
            
            let request = Snippets.securePost(identity, path: identity.micropubMediaEndpoint, arguments: [:], body: formData)
            request.headerFields["Content-Type"] = "multipart/form-data; boundary=\(boundary)"

            return UUHttpSession.executeRequest(request, { (parsedServerResponse) in
                
                let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
                completion(parsedServerResponse.httpError, publishedPath)
            })
            
        }

        static func uploadVideo(_ identity : Snippets.Configuration, data : Data, completion: @escaping(Error?, String?, String?)->()) -> UUHttpRequest?
        {
            // Pre-flight check to see if we are even configured...
            if identity.micropubToken.count == 0 {
                completion(SnippetsError.invalidOrMissingToken, nil, nil)
                return nil
            }

            var formData : Data = Data()
            let imageName = "file"
            let boundary = ProcessInfo.processInfo.globallyUniqueString
                    
            if let blogUid = identity.micropubUid {
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
            
            let request = Snippets.securePost(identity, path: identity.micropubMediaEndpoint, arguments: [:], body: formData)
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
    }

}
