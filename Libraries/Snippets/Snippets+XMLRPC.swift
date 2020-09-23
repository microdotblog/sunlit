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

import UUSwift

extension Snippets {
    
    public class XMLRPC {
    
        @objc public class Request : NSObject {

            @objc static public func publishPostRequest(identity : Snippets.Configuration, existingPost : Bool) -> Snippets.XMLRPC.Request {
            
                var method = ""
                if (identity.type == .wordPress && existingPost) {
                    method = "wp.editPost"
                }
                else if (identity.type == .wordPress) {
                    method = "wp.newPost"
                }
                else if (existingPost) {
                    method = "metaWeblog.editPost"
                }
                else {
                    method =  "metaWeblog.newPost"
                }

                return Snippets.XMLRPC.Request(identity : identity, method: method)
            }

            @objc static public func publishPhotoRequest(identity : Snippets.Configuration) -> Snippets.XMLRPC.Request {
                let method = "metaWeblog.newMediaObject"
                return Snippets.XMLRPC.Request(identity: identity, method: method)
            }

            @objc static public func unpublishRequest(identity : Snippets.Configuration) -> Snippets.XMLRPC.Request {
                let method = "metaWeblog.deletePost"
                return Snippets.XMLRPC.Request(identity : identity, method: method)
            }
            
            @objc static public func fetchPostInfoRequest(identity : Snippets.Configuration) -> Snippets.XMLRPC.Request {

                var method = "metaWeblog.getPost"
                if identity.type == .wordPress {
                    method = "wp.getPost"
                }

                return Snippets.XMLRPC.Request(identity : identity, method: method)
            }

            @objc public convenience init(identity : Snippets.Configuration, method : String) {
                self.init()

                self.identity = identity
                self.method = method
            }

            var identity : Snippets.Configuration = Snippets.Configuration.xmlRpcConfiguration(username: "", password: "", endpoint: "")
            var method = ""
            
        }
        
        @objc public static func execute(request : Snippets.XMLRPC.Request, params:[Any], completion: @escaping(Error?,Data?) -> ()) -> UUHttpRequest {
            
            let xmlRPCRequest = SnippetsRPCDiscovery(url: request.identity.xmlRpcEndpoint)
            return xmlRPCRequest.sendMethod(method: request.method, params: params) { (response) in
                completion(response.httpError, response.rawResponse)
            }
        }

        @objc public static func editPost(postIdentifier : String,
                                   title : String,
                                   content : String,
                                   postFormat : String,
                                   postCategory : String,
                                   request : Snippets.XMLRPC.Request, completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest {
            
            let params : [Any] = self.buildPostParameters(identity : request.identity,
                                                          postIdentifier: postIdentifier,
                                                          title: title,
                                                          htmlContent: content,
                                                          postFormat: postFormat,
                                                          postCategory: postCategory)

            return self.execute(request: request, params: params)
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


        @objc public static func post(title : String,
                               content : String,
                               postFormat : String,
                               postCategory : String,
                               request : Snippets.XMLRPC.Request, completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest {

            let params : [Any] = self.buildPostParameters(identity:request.identity,
                                                          postIdentifier: nil,
                                                          title: title,
                                                          htmlContent: content,
                                                          postFormat: postFormat,
                                                          postCategory: postCategory)
            
            return self.execute(request: request, params: params) { (error, responseData) in

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
        

        @objc public static func uploadImage(image : SnippetsImage, request : Snippets.XMLRPC.Request, completion: @escaping(Error?, String?, String?) -> ()) -> UUHttpRequest {
            let d = image.uuJpegData(0.8)
            let filename = UUID().uuidString.replacingOccurrences(of: "-", with: "") + ".jpg"
            let params : [Any] = [ request.identity.xmlRpcBlogId,
                                   request.identity.xmlRpcUsername,
                                   request.identity.xmlRpcPassword, [ "name" : filename,
                                                           "type" : "image/jpeg",
                                                           "bits": d! ]]

            return self.execute(request: request, params: params) { (error, responseData) in
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

        @objc public static func uploadVideo(data : Data, request : Snippets.XMLRPC.Request,
                                      completion: @escaping(Error?, String?, String?) -> ()) -> UUHttpRequest {
            
            let filename = UUID().uuidString.replacingOccurrences(of: "-", with: "") + ".mov"
            let params : [Any] = [ request.identity.xmlRpcBlogId,
                                   request.identity.xmlRpcUsername,
                                   request.identity.xmlRpcPassword, [ "name" : filename,
                                                                    "type" : "video/mov",
                                                                    "bits": data ]]
            
            return self.execute(request: request, params: params) { (error, responseData) in
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
        
        @objc public static func unpublish(postIdentifier : String, request : Snippets.XMLRPC.Request, completion: @escaping(Error?) -> ()) -> UUHttpRequest {

            let params : [Any] = [ "", postIdentifier, request.identity.xmlRpcUsername, request.identity.xmlRpcPassword ]
            
            return self.execute(request: request, params: params) { (error, responseData) in
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

        @objc public static func fetchPostURL(postIdentifier : String, request : Snippets.XMLRPC.Request, completion: @escaping(Error?, String?) -> ()) -> UUHttpRequest {
            
            var params : [Any] = [ postIdentifier, request.identity.xmlRpcUsername, request.identity.xmlRpcPassword ]
            if request.identity.type == .wordPress {
                params.append(postIdentifier)
                params.append(["link"])
            }

            return self.execute(request: request, params: params) { (error, responseData) in
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
        
        private static func buildCustomErrorFromResponseFault(_ responseFault : [String : Any]) -> NSError
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
        
        private static func buildPostParameters(identity : Snippets.Configuration,
                                         postIdentifier : String?,
                                         title : String,
                                         htmlContent : String,
                                         postFormat : String,
                                         postCategory : String) -> [Any] {
        
            let content = NSMutableDictionary()
            
            if identity.type == . wordPress {
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
                if identity.type == .wordPress {
                    params = [ identity.xmlRpcBlogId, identity.xmlRpcUsername, identity.xmlRpcPassword, publishedGUID, content ]
                }
                else {
                    params = [ publishedGUID, identity.xmlRpcUsername, identity.xmlRpcPassword, content, publish ]
                }
            }
            else {
                if identity.type == .wordPress  {
                    params = [ identity.xmlRpcBlogId, identity.xmlRpcUsername, identity.xmlRpcPassword, content ]
                }
                else {
                    params = [ identity.xmlRpcBlogId, identity.xmlRpcUsername, identity.xmlRpcPassword, content, publish ]
                }
            }
            return params
        }

    }
}
